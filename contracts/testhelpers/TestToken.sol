/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract TestToken is Ownable {
    using SafeMath for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(
        address indexed minter,
        uint256 value
    );
    event Burn(
        address indexed burner,
        uint256 value
    );

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialAmount)
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        if (_initialAmount != 0) {
            mint(
                msg.sender,
                _initialAmount
            );
        }
    }

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        require(_value <= balances[msg.sender] &&
            _to != address(0),
            "invalid transfer"
        );

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        uint256 allowanceAmount = allowed[_from][msg.sender];
        require(_value <= balances[_from] &&
            _value <= allowanceAmount &&
            _to != address(0),
            "invalid transfer"
        );

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (allowanceAmount < uint256(-1)) {
            allowed[_from][msg.sender] = allowanceAmount.sub(_value);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(
        address _to,
        uint256 _value)
        public
    {
        require(_to != address(0), "no burn allowed");
        totalSupply_ = totalSupply_.add(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(
            address(this),
            _to,
            _value
        );
    }

    function burn(
        uint256 _value)
        public
    {
        require(_value <= balances[msg.sender], "balance too low");
        // no need to require _value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Transfer(
            msg.sender,
            address(this),
            _value
        );
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }

    function balanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}
