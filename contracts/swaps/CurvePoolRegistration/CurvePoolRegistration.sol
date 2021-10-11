pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract CurvePoolRegistration is Ownable {
    mapping(address => mapping(address => uint128)) public TokenPoolID;
    mapping(address => bool) public validPool;
    mapping(address => mapping(address => bool)) public validTokenForPool;

    function addPool(
        address tokenPool,
        address[] memory tokensInPool,
        uint128[] memory tokenIDs
    ) public onlyOwner {
        validPool[tokenPool] = true;
        for (uint256 x = 0; x < tokensInPool.length; x++) {
            TokenPoolID[tokenPool][tokensInPool[x]] = tokenIDs[x];
            validTokenForPool[tokenPool][tokensInPool[x]] = true;
        }
    }

    function disablePool(address tokenPool) public onlyOwner {
        validPool[tokenPool] = false;
    }

    function CheckPoolValidity(address pool) public view returns (bool) {
        return validPool[pool];
    }

    function CheckTokenPoolValidity(address pool, address token)
        public
        view
        returns (bool)
    {
        return validTokenForPool[pool][token];
    }

    function GetTokenPoolID(address pool, address token)
        public
        view
        returns (uint128)
    {
        return TokenPoolID[pool][token];
    }
}
