pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";

contract FixedSwapTokenConverter is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    //toke => ooki per token *1e6
    mapping(address => uint256) public tokenIn;
    address public tokenOut;
    mapping(address => uint256) public totalConverted;

    event FixedSwapTokenConvert(
        address indexed sender,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );


    function setTokenOut(address _tokenOut) public onlyOwner {
        tokenOut = _tokenOut;
    }

    function setTokenIn(address _tokenIn, uint256 _swapRate) public onlyOwner {
        require(_tokenIn != address(0), "address(0)");
        tokenIn[_tokenIn] = _swapRate;
    }

    constructor(address[] memory _tokensIn, uint256[] memory _swapRates, address _tokenOut) public {
        require(_tokensIn.length == _swapRates.length, "!length");
        tokenOut = _tokenOut;
        for(uint256 i = 0; i< _tokensIn.length; i++){
            tokenIn[_tokensIn[i]] = _swapRates[i];
        }
    }

    event Logger(string name, uint256 amount);
    function convert(address token, address receiver, uint256 _tokenAmount) public {
        uint256 _swapRate = tokenIn[token];
        require(_swapRate > 0, "swapRate == 0");
        uint256 _balance = IERC20(token).balanceOf(msg.sender);
        if(_tokenAmount > _balance){
            _tokenAmount = _balance;
        }

        if(_tokenAmount == 0){
            return;
        }

        uint256 _amountOut = _tokenAmount.mul(_swapRate).div(1e6);
        emit Logger("_tokenAmount", _tokenAmount);
        emit Logger("_swapRate", _swapRate);
        emit Logger("_amountOut", _amountOut);
        require(IERC20(tokenOut).balanceOf(address(this)) >= _amountOut, "Migrator: low balance");

        IERC20(token).transferFrom(
            msg.sender,
            DEAD,
            _tokenAmount
        );

        totalConverted[token] += _tokenAmount;
        IERC20(tokenOut).safeTransfer(receiver, _amountOut);
        emit FixedSwapTokenConvert(msg.sender, receiver, token, _tokenAmount, tokenOut, _amountOut);
    }

    function rescue(
            address _receiver,
            uint256 _amount,
            address _token
        )
        external
        onlyOwner
        {
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            if(_amount > _balance){
                _amount = _balance;
            }

        IERC20(_token).safeTransfer(_receiver, _amount);
    }
}