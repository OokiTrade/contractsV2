/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AdvancedTokenStorage.sol";
import "../../../interfaces/IBZx.sol";
import "../../interfaces/IERC20Detailed.sol";

contract LoanTokenSettings is AdvancedTokenStorage {
    using SafeMath for uint256;

    bytes32 internal constant iToken_LowerAdminAddress = 0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b;    // keccak256("iToken_LowerAdminAddress")
    bytes32 internal constant iToken_LowerAdminContract = 0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31;   // keccak256("iToken_LowerAdminContract")

    function()
        external
    {
        revert("fallback not allowed");
    }

    function setLowerAdminValues(
        address _lowerAdmin,
        address _lowerAdminContract)
        public
    {
        assembly {
            sstore(iToken_LowerAdminAddress, _lowerAdmin)
            sstore(iToken_LowerAdminContract, _lowerAdminContract)
        }
    }

    function setDisplayParams(
        string memory _name,
        string memory _symbol)
        public
    {
        name = _name;
        symbol = _symbol;
    }

    function recoverEther(
        address receiver,
        uint256 amount)
        public
    {
        uint256 balance = address(this).balance;
        if (balance < amount)
            amount = balance;

        (bool success,) = receiver.call.value(amount)("");
        require(success,
            "transfer failed"
        );
    }

    function recoverToken(
        address tokenAddress,
        address receiver,
        uint256 amount)
        public
    {
        require(tokenAddress != loanTokenAddress, "invalid token");

        IERC20 token = IERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        if (balance < amount)
            amount = balance;

        require(token.transfer(
            receiver,
            amount),
            "transfer failed"
        );
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        require(_to != address(0), "invalid transfer");

        balances[msg.sender] = balances[msg.sender].sub(_value, "insufficient balance");
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function initialize(
        address _loanTokenAddress,
        string memory _name,
        string memory _symbol)
        public
    {
        loanTokenAddress = _loanTokenAddress;

        name = _name;
        symbol = _symbol;
        decimals = IERC20Detailed(loanTokenAddress).decimals();

        initialPrice = WEI_PRECISION; // starting price of 1
    }
}
