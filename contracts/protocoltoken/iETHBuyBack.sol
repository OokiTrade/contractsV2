/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../interfaces/IERC20.sol";
import "../openzeppelin/Ownable.sol";
import "../openzeppelin/SafeMath.sol";


contract iETHBuyBack is Ownable {
    using SafeMath for uint256;

    // mainnet
    IERC20 public constant iETH = IERC20(0x77f973FCaF871459aa58cd81881Ce453759281bC);
    IERC20 public constant vBZRX = IERC20(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);

    // kovan
    //IERC20 public constant iETH = IERC20(0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9);
    //IERC20 public constant vBZRX = IERC20(0x6F8304039f34fd6A6acDd511988DCf5f62128a32);

    uint256 public iETHSwapRate = 0.0002 ether;

    bool public isActive;
    uint256 public iETHSold;
    uint256 public vBZRXBought;

    mapping (address => uint256) public whitelist;

    function convert(
        uint256 _tokenAmount)
        external
    {
        uint256 whitelistAmount = whitelist[msg.sender];
        require(whitelistAmount != 0 && whitelistAmount >= _tokenAmount, "unauthorized");
        require(isActive, "swap not allowed");

        uint256 buyAmount = _tokenAmount
            .mul(10**18)
            .div(iETHSwapRate);

        iETH.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        vBZRX.transfer(
            msg.sender,
            buyAmount
        );

        // overflow condition cannot be reached since the above will throw for bad amounts
        iETHSold += _tokenAmount;
        vBZRXBought += buyAmount;
        whitelist[msg.sender] = whitelistAmount - _tokenAmount;
    }

    function setWhitelist(
        address[] memory addrs,
        uint256[] memory amounts)
        public
        onlyOwner
    {
        require(addrs.length == amounts.length, "count mismatch");

        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = amounts[i];
        }
    }

    function setActive(
        bool _isActive)
        public
        onlyOwner
    {
        isActive = _isActive;
    }

    function withdrawVBZRX(
        uint256 _amount)
        public
        onlyOwner
    {
        uint256 balance = vBZRX.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        if (_amount != 0) {
            vBZRX.transfer(
                msg.sender,
                _amount
            );
        }
    }

    function withdrawIETH(
        uint256 _amount)
        public
        onlyOwner
    {
        uint256 balance = iETH.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        if (_amount != 0) {
            iETH.transfer(
                msg.sender,
                _amount
            );
        }
    }

    function setiETHSwapRate(
        uint256 _newRate)
        external
        onlyOwner
    {
        iETHSwapRate = _newRate;
    }

    function iETHSwapRateWithCheck(
        address _buyer)
        public
        view
        returns (uint256)
    {
        if (whitelist[_buyer] != 0) {
            return iETHSwapRate;
        }
    }
}
