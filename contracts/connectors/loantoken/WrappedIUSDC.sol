/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/ERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin-4.3.2/utils/math/SafeMath.sol";
import "../../proxies/0_8/Upgradeable_0_8.sol";
import "../../../interfaces/IToken.sol";

contract WrappedIUSDC is Upgradeable_0_8, ERC20Burnable {
    // using SafeMath for uint256;

    uint256 public constant WEI_PRECISION = 10**20;
    address public iTokenAddress;
    address public loanTokenAddress;
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    constructor() ERC20("Wrapped iToken USDC", "WIUSDC") {}

    // function initialize(uint256 amount) public onlyOwner {
    //     _mint(msg.sender, amount);
    // }

    function initialize() public onlyOwner {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Wrapped iToken USDC")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function decimals() public view virtual override returns (uint8) {
        return IERC20Metadata(loanTokenAddress).decimals();
    }

    function setLoanTokenAddress(address iToken, address loanToken)
        public
        onlyOwner
    {
        iTokenAddress = iToken;
        loanTokenAddress = loanToken;
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(
            _token,
            msg.sender,
            _token.balanceOf(address(this))
        );
    }

    // constructor does not modify proxy storage
    function name() public view override returns (string memory) {
        return "Wrapped iToken USDC";
    }

    // constructor does not modify proxy storage
    function symbol() public view override returns (string memory) {
        return "WIUSDC";
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
        require(deadline >= block.timestamp, "WIUSDC: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "WIUSDC: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function _beforeTokenTransfer(
        address, /*from*/
        address to,
        uint256 /*amount*/
    ) internal override {
        require(to != address(this), "ERC20: token contract is receiver");
    }

    function tokenPrice() public view returns (uint256) {
        return IToken(iTokenAddress).tokenPrice();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return
            (super.balanceOf(account) * (tokenPrice()) * (100)) /
            (WEI_PRECISION);
    }

    function balanceOfUnderlying(address account)
        public
        view
        returns (uint256)
    {
        return super.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        amount = (amount * (WEI_PRECISION)) / (tokenPrice()) / (100);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        amount = (amount * (WEI_PRECISION)) / (tokenPrice()) / (100);
        return super.transferFrom(sender, recipient, amount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return (super.totalSupply() * (tokenPrice()) * (100)) / (WEI_PRECISION);
    }

    function mintFromIToken(address recv, uint256 depositAmount) public {
        IERC20(iTokenAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        _mint(recv, depositAmount);
    }

    function setApproval() public onlyOwner {
        IERC20(loanTokenAddress).approve(iTokenAddress, 0);
        IERC20(loanTokenAddress).approve(iTokenAddress, type(uint256).max);
    }

    function mint(address recv, uint256 depositAmount) public {
        IERC20(loanTokenAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        _mint(recv, IToken(iTokenAddress).mint(address(this), depositAmount));
    }

    function burnToIToken(address recv, uint256 burnAmount) public {
        uint256 amount = super.balanceOf(_msgSender());
        if (burnAmount > amount) {
            burnAmount = amount;
        }

        _burn(_msgSender(), burnAmount);
        IERC20(iTokenAddress).transfer(recv, burnAmount);
    }

    function burn(address recv, uint256 burnAmount) public {
        uint256 amount = super.balanceOf(_msgSender());
        if (burnAmount > amount) {
            burnAmount = amount;
        }

        _burn(_msgSender(), burnAmount);
        IToken(iTokenAddress).burn(recv, burnAmount);
    }
}
