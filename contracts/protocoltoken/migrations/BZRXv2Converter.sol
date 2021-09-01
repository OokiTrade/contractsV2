/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: Apache License, Version 2.0.
pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "../OokiToken.sol";


contract BZRXv2Converter is Ownable {

    event ConvertBZRX(
        address indexed sender,
        uint256 amount
    );

    IERC20 public constant BZRXv1 = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);
    // IERC20 public constant vBZRXv1 = IERC20(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);
    OokiToken public constant OOKI = OokiToken(0xC5c66f91fE2e395078E0b872232A20981bc03B15);
    // VBZRXv2VestingToken public vBZRXv2;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public totalConverted;
    uint256 public totalVestingConverted;
    uint256 public terminationTimestamp;

    function convert(
        address receiver,
        uint256 _tokenAmount)
        external
    {
        BZRXv1.transferFrom(
            msg.sender,
            DEAD, // burn address, since transfers to address(0) are not allowed by the token
            _tokenAmount
        );

        // we mint burned amount
        OOKI.mint(receiver, _tokenAmount);

        // overflow condition cannot be reached since the above will throw for bad amounts
        totalConverted += _tokenAmount;

        emit ConvertBZRX(
            receiver,
            _tokenAmount
        );
    }

    // open convert tool to the public
    function initialize()
        external
        onlyOwner
    {
        require(terminationTimestamp == 0, "already initialized");
        terminationTimestamp = _getTimestamp() + 60 * 60 * 24 * 365; // one year from now
    }

    // funds unclaimed after one year can be rescued
    function rescue(
        address _receiver,
        uint256 _amount,
        address _token)
        external
        onlyOwner
    {
        require(_getTimestamp() > terminationTimestamp, "unauthorized");

        IERC20(_token).transfer(
            _receiver,
            _amount
        );
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}