/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/token/ERC20/IERC20.sol";
import "@openzeppelin-2.5.0/ownership/Ownable.sol";
import "@openzeppelin-2.5.0/math/SafeMath.sol";


interface iETHBuyBackV1 {
    function transferOwnership(
        address _newOwner)
        external;

    function setWhitelist(
        address[] calldata addrs,
        uint256[] calldata amounts)
        external;

    function whitelist(
        address _buyer)
        external
        view
        returns (uint256);

    function iETHSold()
        external
        view
        returns (uint256);

    function vBZRXBought()
        external
        view
        returns (uint256);
}

contract iETHBuyBackV2 is Ownable {
    using SafeMath for uint256;

    // mainnet
    IERC20 public constant iETH = IERC20(0x77f973FCaF871459aa58cd81881Ce453759281bC);
    IERC20 public constant vBZRX = IERC20(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);
    iETHBuyBackV1 internal constant v1 = iETHBuyBackV1(0x85A25f18ba56163450d597E521c7A79F552c93d2);

    // kovan
    //IERC20 public constant iETH = IERC20(0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9);
    //IERC20 public constant vBZRX = IERC20(0x6F8304039f34fd6A6acDd511988DCf5f62128a32);
    //iETHBuyBackV1 internal constant v1 = iETHBuyBackV1(0x8D639BAe9e249Ef52AD54Cfa36fF310C89Eb1f4a);

    uint256 public iETHSwapRate;
    uint256 public iETHSwapRateWL;

    bool public isActive = true;
    uint256 public iETHSold;
    uint256 public vBZRXBought;

    constructor(
        uint256 _iETHSwapRate,
        uint256 _iETHSwapRateWL,
        address _newOwner)
        public
    {
        iETHSwapRate = _iETHSwapRate;
        iETHSwapRateWL = _iETHSwapRateWL;

        if (msg.sender != _newOwner) {
            transferOwnership(_newOwner);
        }

        iETHSold = v1.iETHSold();
        vBZRXBought = v1.vBZRXBought();
    }

    function convert(
        uint256 _tokenAmount)
        public
    {
        uint256 whitelistAmount = whitelist(msg.sender);
        bool isWhiteListed = whitelistAmount != 0;

        uint256 swapRate;
        if (isWhiteListed) {
            if (_tokenAmount > whitelistAmount) {
                _tokenAmount = whitelistAmount;
            }
            swapRate = iETHSwapRateWL;
        } else {
            swapRate = iETHSwapRate;
        }

        require(swapRate != 0 && _tokenAmount != 0 && isActive, "swap not allowed");

        uint256 buyAmount = _tokenAmount
            .mul(10**18)
            .div(swapRate);

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

        if (isWhiteListed) {
            address[] memory addrs = new address[](1);
            addrs[0] = msg.sender;

            uint256[] memory amounts = new uint256[](1);
            amounts[0] = whitelistAmount - _tokenAmount;

            v1.setWhitelist(
                addrs,
                amounts
            );
        }
    }

    function setWhitelist(
        address[] memory addrs,
        uint256[] memory amounts)
        public
        onlyOwner
    {
        v1.setWhitelist(
            addrs,
            amounts
        );
    }

    function transferV1Ownership(
        address _newOwner)
        public
        onlyOwner
    {
        v1.transferOwnership(_newOwner);
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

    function setiETHSwapRates(
        uint256 _newRate,
        uint256 _newRateWL)
        external
        onlyOwner
    {
        iETHSwapRate = _newRate;
        iETHSwapRateWL = _newRateWL;
    }

    function iETHSwapRateWithCheck(
        address _buyer)
        public
        view
        returns (uint256)
    {
        if (whitelist(_buyer) != 0) {
            return iETHSwapRateWL;
        } else {
            return iETHSwapRate;
        }
    }

    function whitelist(
        address _buyer)
        public
        view
        returns (uint256)
    {
        return v1.whitelist(_buyer);
    }
}
