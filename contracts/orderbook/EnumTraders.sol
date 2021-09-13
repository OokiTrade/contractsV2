pragma solidity ^0.8.4;
library getActiveTraders{
    struct orderSet{
        mapping(address=>uint) idx;
        address[] vals;
    }
    function addTrader(orderSet storage hist, address val) internal returns(bool){
        if(inVals(hist,val) == false){
            hist.vals.push(val);
            hist.idx[val] = length(hist);
            return true;
        }else {
            return false;
        }
    }
    function removeTrader(orderSet storage hist, address val) internal returns(bool){
        if(inVals(hist,val)){
            uint delIdx = hist.idx[val] - 1;
            uint lastIdx = hist.vals.length - 1;
            if(delIdx != lastIdx){
                address tempVal = hist.vals[lastIdx];
                hist.vals[delIdx] = tempVal;
                hist.idx[tempVal] = delIdx+1;
            }
            delete hist.idx[val];
            hist.vals.pop();
            return true;
        }else{
            return false;
        }
    }
    function inVals(orderSet storage hist, address val) internal view returns(bool){
        return hist.idx[val] != 0;
    }
    function length(orderSet storage hist) internal view returns(uint){
        return hist.vals.length;
    }
    function get(orderSet storage hist, uint idx) internal view returns (address){
        return hist.vals[idx];
    }
    function enums(orderSet storage hist, uint start, uint len) internal view returns(address[] memory out){
        uint stop = start+len;
        require(stop>=start);
        stop = hist.vals.length < stop ? hist.vals.length : stop;
        if(start >= stop || stop == 0){
            return out;
        }
        out = new address[](stop-start);
        for(uint i=start;i<stop;i++){
            out[i-start] = hist.vals[i];
        }
        return out;
    }
}