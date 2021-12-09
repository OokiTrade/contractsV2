pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract CurvePoolRegistration is Ownable {
    mapping(address => bool) public validPool;
    mapping(address => uint256) public poolType;

    function addPool(address tokenPool, uint256 PoolT) public {
        validPool[tokenPool] = true;
		poolType[tokenPool] = PoolT;
    }

    function disablePool(address tokenPool) public {
        validPool[tokenPool] = false;
    }

    function CheckPoolValidity(address pool) public view returns (bool) {
        return validPool[pool];
    }
	
	function getPoolType(address tokenPool) public view returns (uint256) {
		return poolType[tokenPool];
	}
}
