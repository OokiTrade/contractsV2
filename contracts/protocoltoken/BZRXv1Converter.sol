/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../interfaces/IERC20.sol";
import "../openzeppelin/Ownable.sol";


contract BZRXv1Converter is Ownable {

    event ConvertBZRX(
        address indexed sender,
        uint256 amount
    );

    IERC20 public constant BZRXv1 = IERC20(0x1c74cFF0376FB4031Cd7492cD6dB2D66c3f2c6B9);
    IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);

    uint256 public totalConverted;
    uint256 public terminationTimestamp;

    function convert(
        uint256 _tokenAmount)
        external
    {
        require((
            _getTimestamp() < terminationTimestamp &&
            msg.sender != address(1)) ||
            msg.sender == owner(), "convert not allowed");

        BZRXv1.transferFrom(
            msg.sender,
            address(1), // burn address, since transfers to address(0) are not allowed by the token
            _tokenAmount
        );

        BZRX.transfer(
            msg.sender,
            _tokenAmount
        );

        // overflow condition cannot be reached since the above will throw for bad amounts
        totalConverted += _tokenAmount;

        emit ConvertBZRX(
            msg.sender,
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
        uint256 _amount)
        external
        onlyOwner
    {
        require(_getTimestamp() > terminationTimestamp, "unauthorized");

        BZRX.transfer(
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