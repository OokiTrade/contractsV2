/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AdvancedTokenStorage.sol";
import "./StorageExtension.sol";
import "../../../interfaces/IBZx.sol";
import "../../interfaces/IERC20Detailed.sol";

contract LoanTokenSettings is AdvancedTokenStorage, StorageExtension {
    using SafeMath for uint256;

    //address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxContract = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant bZxContract = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    address public constant bZxContract = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum

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

        IERC20(_loanTokenAddress).approve(bZxContract, uint256(-1));
    }

    function revokeApproval(
        address _loanTokenAddress)
        public
    {
        if (_loanTokenAddress == address(0)) {
            IERC20(loanTokenAddress).approve(bZxContract, 0);
        } else {
            IERC20(_loanTokenAddress).approve(bZxContract, 0);
        }
    }
}
