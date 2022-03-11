/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/ERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "./MintCoordinator.sol";


contract BZRXv2Converter is Ownable {

    event ConvertBZRX(
        address indexed sender,
        uint256 amount
    );

    IERC20 public constant BZRXv1 = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    MintCoordinator public MINT_COORDINATOR;
    uint256 public totalConverted;

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
        MINT_COORDINATOR.mint(receiver, _tokenAmount * 10); // we do a 10x split

        // overflow condition cannot be reached since the above will throw for bad amounts
        totalConverted += _tokenAmount;

        emit ConvertBZRX(
            receiver,
            _tokenAmount
        );
    }

    // open convert tool to the public
    function initialize(
        MintCoordinator _MINT_COORDINATOR)
        external
        onlyOwner
    {
        require(address(MINT_COORDINATOR) == address(0), "already initialized");
        MINT_COORDINATOR = _MINT_COORDINATOR;
    }

    // allows the DAO to rescue tokens accidently sent to the contract
    function rescue(
        IERC20 _token)
        external
        onlyOwner
    {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }
}