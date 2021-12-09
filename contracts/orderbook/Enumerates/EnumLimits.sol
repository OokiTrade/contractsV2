pragma solidity ^0.8.4;

library OrderRecords {
    struct orderSet {
        mapping(uint256 => uint256) idx;
        uint256[] vals;
    }

    function addOrderNum(orderSet storage hist, uint256 val)
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

    function removeOrderNum(orderSet storage hist, uint256 val)
        internal
        returns (bool)
    {
        if (inVals(hist, val)) {
            uint256 delIdx = hist.idx[val] - 1;
            uint256 lastIdx = hist.vals.length - 1;
            if (delIdx != lastIdx) {
                uint256 tempVal = hist.vals[lastIdx];
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

    function inVals(orderSet storage hist, uint256 val)
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
        returns (uint256)
    {
        return hist.vals[idx];
    }

    function enums(
        orderSet storage hist,
        uint256 start,
        uint256 len
    ) internal view returns (uint256[] memory out) {
        uint256 stop = start + len;
        require(stop >= start);
        stop = hist.vals.length < stop ? hist.vals.length : stop;
        if (start >= stop || stop == 0) {
            return out;
        }
        out = new uint256[](stop - start);
        for (uint256 i = start; i < stop; i++) {
            out[i - start] = hist.vals[i];
        }
        return out;
    }
}
