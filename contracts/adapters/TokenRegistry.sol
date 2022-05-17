/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../interfaces/IBZx.sol";

contract TokenRegistry {

    //address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxContract = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant bZxContract = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    //address public constant bZxContract = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum
    address public constant bZxContract = 0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f; // evmos
    //address public constant bZxContract = 0x3155D5b330c3023458b2fF1d0733D0F419a3D52e; // optimism

    struct TokenMetadata {
        address token; // iToken
        address asset; // underlying asset
    }

    function getTokens(uint256 _start, uint256 _count)
        external
        view
        returns (TokenMetadata[] memory metadata)
    {
        address[] memory loanPool;
        IBZx theProtocol = IBZx(bZxContract);
        loanPool = theProtocol.getLoanPoolsList(_start, _count);

        metadata = new TokenMetadata[](loanPool.length);
        for (uint256 i = 0; i < loanPool.length; i++) {
            metadata[i].token = loanPool[i];
            metadata[i].asset = theProtocol.loanPoolToUnderlying(loanPool[i]);
        }
    }
}
