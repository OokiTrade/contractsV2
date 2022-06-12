pragma solidity ^0.5.0;

library VolumeOracle {
    struct Observation {
        uint32 blockTimestamp;
        int56 volCumulative;
    }

    /// @param last The specified observation
    /// @param blockTimestamp The new timestamp
    /// @param tick The active tick
    /// @return Observation The newly populated observation
    function convert(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick
    ) private pure returns (Observation memory) {
        return
            Observation({
                blockTimestamp: blockTimestamp,
                volCumulative: last.volCumulative + int56(tick)
            });
    }

    /// @param self oracle array
    /// @param index most recent observation index
    /// @param blockTimestamp timestamp of observation
    /// @param tick active tick
    /// @param cardinality populated elements
    /// @return indexUpdated The new index
    function write(
        Observation[256] storage self,
        uint8 index,
        uint32 blockTimestamp,
        int24 tick,
        uint8 cardinality,
        uint32 minDelta
    ) public returns (uint8 indexUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation in last minDelta seconds
        if (last.blockTimestamp + minDelta >= blockTimestamp) {
            self[index] = convert(last, last.blockTimestamp, tick);
            return index;
        }
        indexUpdated = (index + 1) % cardinality;
        self[indexUpdated] = convert(last, blockTimestamp, tick);
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param index latest index
    /// @param cardinality populated elements
    function binarySearch(
        Observation[256] storage self,
        uint32 target,
        uint8 index,
        uint8 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            if (beforeOrAt.blockTimestamp == 0) {
                l = 0;
                r = index;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;
            bool targetBeforeOrAt = atOrAfter.blockTimestamp >= target;
            if (!targetAtOrAfter) {
                r = i - 1;
                continue;
            } else if (!targetBeforeOrAt) {
                l = i + 1;
                continue;
            }
            break;
        }
    }

    /// @param self oracle array
    /// @param target targeted timestamp to retrieve value
    /// @param index latest index
    /// @param cardinality populated elements
    function getSurroundingObservations(
        Observation[256] storage self,
        uint32 target,
        uint8 index,
        uint8 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {

        beforeOrAt = self[index];

        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                return (beforeOrAt, atOrAfter);
            } else {
                return (beforeOrAt, beforeOrAt);
            }
        }

        beforeOrAt = self[(index + 1) % cardinality];
        if (beforeOrAt.blockTimestamp == 0) beforeOrAt = self[0];
        require(beforeOrAt.blockTimestamp <= target && beforeOrAt.blockTimestamp != 0, "OLD");
        return binarySearch(self, target, index, cardinality);
    }

    function checkLastTradeTime(
        Observation[256] storage self,
        uint32 time,
        uint32 secondsAgo,
        uint8 index
    ) internal view returns (bool) {
        return self[index].blockTimestamp >= time-secondsAgo;
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgo lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return volCumulative cumulative volume
    function observeSingle(
        Observation[256] storage self,
        uint32 time,
        uint32 secondsAgo,
        uint8 index,
        uint8 cardinality
    ) internal view returns (int56 volCumulative) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            return last.volCumulative;
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, target, index, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // left boundary
            return beforeOrAt.volCumulative;
        } else {
            // right boundary
            return atOrAfter.volCumulative;
        }
    }

    /// @param self oracle array
    /// @param time current timestamp
    /// @param secondsAgos lookback time
    /// @param index latest index
    /// @param cardinality populated elements
    /// @return volDelta Volume delta based on time period
    function volumeDelta(
        Observation[256] storage self,
        uint32 time,
        uint32[2] memory secondsAgos,
        uint8 index,
        uint8 cardinality
    ) public view returns (int24 volDelta) {
        if (!checkLastTradeTime(self, time, secondsAgos[0], index)) return 0; //no trades since the furthest seconds back
        int56 firstPoint = observeSingle(self, time, secondsAgos[1], index, cardinality);
        int56 secondPoint = observeSingle(self, time, secondsAgos[0], index, cardinality);
        return int24(firstPoint-secondPoint);
    }
}