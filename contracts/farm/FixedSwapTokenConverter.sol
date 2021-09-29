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

    //ooki per token *1e6
    uint256 public swapRate;
    address public tokenIn;
    address public tokenOut;
    uint256 public totalConverted;

    event FixedSwapTokenConvert(
        address indexed sender,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );


    function setTokens(address _tokenIn, address _tokenOut) public onlyOwner {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
    }

    function setSwapRate(uint256 _rate) public onlyOwner {
        swapRate = _rate;
    }

    constructor(address _tokenIn, address _tokenOut, uint256 _swapRate) public {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        swapRate = _swapRate;
    }

    function convert(address receiver, uint256 _tokenAmount) public {

        uint256 _balance = IERC20(tokenIn).balanceOf(msg.sender);
        if(_tokenAmount > _balance){
            _tokenAmount = _balance;
        }

        if(_tokenAmount == 0){
            return;
        }

        uint256 _amountOut = _tokenAmount.mul(swapRate).div(1e6);
        require(IERC20(tokenOut).balanceOf(address(this)) >= _amountOut, "Migrator: low balance");

        IERC20(tokenIn).transferFrom(
            msg.sender,
            DEAD,
            _tokenAmount
        );

        totalConverted += _tokenAmount;
        IERC20(tokenOut).safeTransfer(receiver, _amountOut);
        emit FixedSwapTokenConvert(msg.sender, receiver, tokenIn, _tokenAmount, tokenOut, _amountOut);
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