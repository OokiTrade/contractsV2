/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

//0xd061D61a4d941c39E5453435B6345Dc261C2fcE0 eth mainnet
interface ICurveMinter {

    function mint(
        address _addr
    )
    external;
}
