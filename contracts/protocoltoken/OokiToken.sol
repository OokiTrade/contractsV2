/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/ERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";

contract OokiToken is Upgradeable_0_8, ERC20Burnable {
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    constructor() ERC20("Ooki Token", "OOKI") {}

    function initialize() public onlyOwner {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Ooki Token")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    // constructor does not modify proxy storage
    function name() public view override returns (string memory) {
        return "Ooki Token";
    }

    // constructor does not modify proxy storage
    function symbol() public view override returns (string memory) {
        return "OOKI";
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "OOKI: EXPIRED");
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "OOKI: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function _beforeTokenTransfer(
        address /*from*/,
        address to,
        uint256 /*amount*/
    ) internal override {
        require(to != address(this), "ERC20: token contract is receiver");
    }
}
