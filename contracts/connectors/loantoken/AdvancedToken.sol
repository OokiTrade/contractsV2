/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./AdvancedTokenStorage.sol";


contract AdvancedToken is AdvancedTokenStorage {
    using SafeMath for uint256;

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        return _approve(msg.sender, _spender, _value);
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
        require(deadline >= block.timestamp, "iToken: EXPIRED");
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "iToken: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender]
            .add(_addedValue);
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender];
        if (_subtractedValue >= _allowed) {
            _allowed = 0;
        } else {
            _allowed -= _subtractedValue;
        }
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value)
        internal
        returns (bool)
    {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }

    function _mint(
        address _to,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        require(_to != address(0), "15");

        uint256 _balance = balances[_to]
            .add(_tokenAmount);
        balances[_to] = _balance;

        totalSupply_ = totalSupply_
            .add(_tokenAmount);

        emit Mint(_to, _tokenAmount, _assetAmount, _price);
        emit Transfer(address(0), _to, _tokenAmount);

        return _balance;
    }

    function _burn(
        address _who,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        uint256 _balance = balances[_who].sub(_tokenAmount, "16");
        
        // a rounding error may leave dust behind, so we clear this out
        if (_balance <= 10) {
            _tokenAmount = _tokenAmount.add(_balance);
            _balance = 0;
        }
        balances[_who] = _balance;

        totalSupply_ = totalSupply_.sub(_tokenAmount);

        emit Burn(_who, _tokenAmount, _assetAmount, _price);
        emit Transfer(_who, address(0), _tokenAmount);

        return _balance;
    }
}
