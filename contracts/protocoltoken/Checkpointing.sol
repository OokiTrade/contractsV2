/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


/**
 * Copyright (C) 2019 Aragon One <https://aragon.one/>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
/**
 * @title Checkpointing
 * @notice Checkpointing library for keeping track of historical values based on an arbitrary time
 *         unit (e.g. seconds or block numbers).
 * @dev Adapted from:
 *   - Checkpointing  (https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/Checkpointing.sol)
 */
library Checkpointing {

    struct Checkpoint {
        uint256 time;
        uint256 value;
    }

    struct History {
        Checkpoint[] history;
    }

    function addCheckpoint(
        History storage _self,
        uint256 _time,
        uint256 _value)
        internal
    {
        uint256 length = _self.history.length;
        if (length == 0) {
            _self.history.push(Checkpoint(_time, _value));
        } else {
            Checkpoint storage currentCheckpoint = _self.history[length - 1];
            uint256 currentCheckpointTime = currentCheckpoint.time;

            if (_time > currentCheckpointTime) {
                _self.history.push(Checkpoint(_time, _value));
            } else if (_time == currentCheckpointTime) {
                currentCheckpoint.value = _value;
            } else { // ensure list ordering
                revert("past-checkpoint");
            }
        }
    }

    function getValueAt(
        History storage _self,
        uint256 _time)
        internal
        view
        returns (uint256)
    {
        return _getValueAt(_self, _time);
    }

    function lastUpdated(
        History storage _self)
        internal
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;
        if (length != 0) {
            return _self.history[length - 1].time;
        }
    }

    function latestValue(
        History storage _self)
        internal
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;
        if (length != 0) {
            return _self.history[length - 1].value;
        }
    }

    function _getValueAt(
        History storage _self,
        uint256 _time)
        private
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        Checkpoint storage lastCheckpoint = _self.history[lastIndex];
        if (_time >= lastCheckpoint.time) {
            return lastCheckpoint.value;
        }

        // Check first checkpoint (if not already checked with the above check on last)
        if (length == 1 || _time < _self.history[0].time) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;

        while (high != low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            Checkpoint storage checkpoint = _self.history[mid];
            uint256 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return checkpoint.value;
            }
        }

        return _self.history[low].value;
    }
}
