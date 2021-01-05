/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../openzeppelin/Ownable.sol";
import "../../openzeppelin/SafeERC20.sol";


contract IChiToken {
    function balanceOf(address _who) public view returns (uint256);
    function freeUpTo(uint256 value) public returns (uint256);
    function freeFromUpTo(address from, uint256 value) public returns (uint256);
}

contract TokenHolder is Ownable {
    using SafeERC20 for IERC20;

    IChiToken constant public gasToken = IChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    mapping (address => bool) public delegatedCallers;

    constructor(
        address _owner)
        public
    {
        transferOwnership(_owner);
    }

    function freeUpTo(
        uint256 value)
        external
        returns (uint256)
    {
        require(delegatedCallers[msg.sender], "unauthorized");
        return gasToken.freeUpTo(
            value
        );
    }

    function freeFromUpTo(
        address from,
        uint256 value)
        external
        returns (uint256)
    {
        require(delegatedCallers[msg.sender], "unauthorized");
        return gasToken.freeFromUpTo(
            from,
            value
        );
    }

    function giveApproval(
        IERC20 token,
        address spender,
        uint256 amount)
        external
        onlyOwner
    {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance != amount) {
            if (allowance != 0) {
                token.safeApprove(spender, 0);
            }
            token.safeApprove(spender, amount);
        }
    }

    function clearApproval(
        IERC20 token,
        address spender)
        external
        onlyOwner
    {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance != 0) {
            token.safeApprove(spender, 0);
        }
    }

    function withdrawToken(
        IERC20 token,
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (uint256 withdrawAmount)
    {
        withdrawAmount = token.balanceOf(address(this));
        if (withdrawAmount > amount) {
            withdrawAmount = amount;
        }
        if (withdrawAmount != 0) {
            token.safeTransfer(
                receiver,
                withdrawAmount
            );
        }
    }

    function withdrawEther(
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (uint256 withdrawAmount)
    {
        withdrawAmount = address(this).balance;
        if (withdrawAmount > amount) {
            withdrawAmount = amount;
        }
        if (withdrawAmount != 0) {
            Address.sendValue(
                receiver,
                withdrawAmount
            );
        }
    }

    function setDelegatedCallers(
        address[] calldata addrs,
        bool[] calldata toggles)
        external
        onlyOwner
    {
        require(addrs.length == toggles.length, "count mismatch");

        for (uint256 i = 0; i < addrs.length; i++) {
            delegatedCallers[addrs[i]] = toggles[i];
        }
    }
}
