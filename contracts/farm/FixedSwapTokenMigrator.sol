pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";

contract FixedSwapTokenMigrator is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //token => ooki per token *1e6
    mapping(address=>uint256) public swapRate;
    address public tokenOut;

    event Withdraw(address user, uint256 amount);
    event Migrate(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    function setTokenOut(address _tokenOut) public onlyOwner {
        tokenOut = _tokenOut;
    }

    function setSwapRate(address _token, uint256 _rate) public onlyOwner {
        swapRate[_token] = _rate;
    }

    constructor(address _tokenOut, address[] memory _tokens, uint256[] memory _rates) public {
        tokenOut = _tokenOut;
        require(_tokens.length == _rates.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            swapRate[_tokens[i]] = _rates[i];
        }
    }

    function migrate(address _token, uint256 _amountIn) public {
        require(IERC20(_token).balanceOf(msg.sender) >=_amountIn, "Token low balance");

        uint256 _rate = swapRate[_token];
        require(_rate > 0, "Unsupported token");
        uint256 _amountOut = _amountIn.mul(_rate).div(1e6);
        require(IERC20(tokenOut).balanceOf(address(this)) >= _amountOut, "Migrator low balance");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, _amountOut);
        emit Migrate(msg.sender, _token, tokenOut, _amountIn, _amountOut);
    }

    function withdraw(address _token, uint256 _amount) public onlyOwner {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        if(_amount > _balance){
            _amount = _balance;
        }

        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(_token, _amount);
    }
}