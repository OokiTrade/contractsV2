pragma solidity ^0.8.4;

library OrderEntry {
    struct orderSet {
        mapping(bytes32 => uint256) idx;
        bytes32[] vals;
    }

    function addTrade(orderSet storage hist, bytes32 val)
        internal
        returns (bool)
    {
        if (inVals(hist, val) == false) {
            hist.vals.push(val);
            hist.idx[val] = length(hist);
            return true;
        } else {
            return false;
        }
    }

    function removeTrade(orderSet storage hist, bytes32 val)
        internal
        returns (bool)
    {
        if (inVals(hist, val)) {
            uint256 delIdx = hist.idx[val] - 1;
            uint256 lastIdx = hist.vals.length - 1;
            if (delIdx != lastIdx) {
                bytes32 tempVal = hist.vals[lastIdx];
                hist.vals[delIdx] = tempVal;
                hist.idx[tempVal] = delIdx + 1;
            }
            delete hist.idx[val];
            hist.vals.pop();
            return true;
        } else {
            return false;
        }
    }

    function inVals(orderSet storage hist, bytes32 val)
        internal
        view
        returns (bool)
    {
        return hist.idx[val] != 0;
    }

    function length(orderSet storage hist) internal view returns (uint256) {
        return hist.vals.length;
    }

    function get(orderSet storage hist, uint256 idx)
        internal
        view
        returns (bytes32)
    {
        return hist.vals[idx];
    }

    function enums(
        orderSet storage hist,
        uint256 start,
        uint256 len
    ) internal view returns (bytes32[] memory out) {
        uint256 stop = start + len;
        require(stop >= start);
        stop = hist.vals.length < stop ? hist.vals.length : stop;
        if (start >= stop || stop == 0) {
            return out;
        }
        out = new bytes32[](stop - start);
        for (uint256 i = start; i < stop; i++) {
            out[i - start] = hist.vals[i];
        }
        return out;
    }
}
