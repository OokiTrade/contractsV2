/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface TheProtocol{
    function getLoanPoolsList(
        uint256 start,
        uint256 count)
        external
        view
        returns (address[] memory loanPoolsList);

    function loanPoolToUnderlying(address _loanPool)
        external
        view
        returns(address);
}

contract TokenRegistry {

    address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxContract = 0xC47812857A74425e2039b57891a3DFcF51602d5d; // bsc

    struct TokenMetadata {
        address token; // iToken
        address asset; // underlying asset
    }

    function getTokens(
        uint256 _start,
        uint256 _count)
        external
        view
        returns (TokenMetadata[] memory metadata)
    {
        address[] memory loanPool;
        TheProtocol theProtocol = TheProtocol(bZxContract);
        loanPool = theProtocol.getLoanPoolsList(_start, _count);

        metadata = new TokenMetadata[](loanPool.length);
        for(uint256 i = 0; i < loanPool.length; i++){
            metadata[i].token = loanPool[i];
            metadata[i].asset = theProtocol.loanPoolToUnderlying(loanPool[i]);
        }
    }
}
