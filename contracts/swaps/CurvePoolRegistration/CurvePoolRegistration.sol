pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract CurvePoolRegistration is Ownable {
    mapping(address => bool) public validPool;

    function addPool(
        address tokenPool
    ) public {
        validPool[tokenPool] = true;
    }

    function disablePool(address tokenPool) public {
        validPool[tokenPool] = false;
    }

    function CheckPoolValidity(address pool) public view returns (bool) {
        return validPool[pool];
    }
}
