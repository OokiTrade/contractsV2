/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
/// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";

contract FixedSwapTokenConverterNotBurn is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    //token => ooki per token *1e18
    mapping(address => uint256) public tokenIn;
    address public tokenOut;
    mapping(address => uint256) public totalConverted;

    address public defaultToken;

    event FixedSwapTokenConvert(
        address indexed sender,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );


    function setDefaultToken(address _token) public onlyOwner {
        defaultToken = _token;
    }

    function setTokenOut(address _tokenOut) public onlyOwner {
        tokenOut = _tokenOut;
    }

    function setTokenIn(address _tokenIn, uint256 _swapRate) public onlyOwner {
        require(_tokenIn != address(0), "address(0)");
        tokenIn[_tokenIn] = _swapRate;
    }

    constructor(address[] memory _tokensIn, uint256[] memory _swapRates, address _tokenOut, address _defaultToken) public {
        require(_tokensIn.length == _swapRates.length, "!length");
        tokenOut = _tokenOut;
        defaultToken = _defaultToken;
        for(uint256 i = 0; i< _tokensIn.length; i++){
            tokenIn[_tokensIn[i]] = _swapRates[i];
        }
    }

    function _convert(address receiver, address _token, uint256 _tokenAmount) internal {
        
        uint256 _swapRate = tokenIn[_token];
        require(_swapRate != 0, "swapRate == 0");
        
        uint256 _balance = IERC20(_token).balanceOf(msg.sender);
        if(_tokenAmount > _balance){
            _tokenAmount = _balance;
        }
        if(_tokenAmount == 0) {
            return;
        }

        uint256 _amountOut = _tokenAmount.mul(_swapRate).div(1e18);
        require(IERC20(tokenOut).balanceOf(address(this)) >= _amountOut, "Migrator: low balance");

        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        totalConverted[_token] += _tokenAmount;
        IERC20(tokenOut).safeTransfer(receiver, _amountOut);
        emit FixedSwapTokenConvert(msg.sender, receiver, _token, _tokenAmount, tokenOut, _amountOut);
    }

    function convert(address receiver, uint256 _tokenAmount) public{
        require(defaultToken != address(0), "default is not set");
        _convert(receiver, defaultToken, _tokenAmount);
    }

    function convert(address receiver, address[] memory _tokens, uint256[] memory _amounts) public {
        for(uint256 i = 0; i< _tokens.length; i++){
            _convert(receiver, _tokens[i], _amounts[i]);
        }
    }

    function rescue(IERC20 _token) public onlyOwner {
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }
}