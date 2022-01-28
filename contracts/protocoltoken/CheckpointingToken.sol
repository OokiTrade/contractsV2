/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/token/ERC20/IERC20.sol";
import "./Checkpointing.sol";


contract CheckpointingToken is IERC20 {
    using Checkpointing for Checkpointing.History;

    mapping (address => mapping (address => uint256)) internal allowances_;

    mapping (address => Checkpointing.History) internal balancesHistory_;

    struct Checkpoint {
        uint256 time;
        uint256 value;
    }

    struct History {
        Checkpoint[] history;
    }

    // override this function if a totalSupply should be tracked
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return 0;
    }

    function balanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balanceOfAt(_owner, block.number);
    }

    function balanceOfAt(
        address _owner,
        uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        return balancesHistory_[_owner].getValueAt(_blockNumber);
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowances_[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowances_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        return transferFrom(
            msg.sender,
            _to,
            _value
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        require(previousBalanceFrom >= _value, "insufficient-balance");

        if (_from != msg.sender && allowances_[_from][msg.sender] != uint(-1)) {
            require(allowances_[_from][msg.sender] >= _value, "insufficient-allowance");
            allowances_[_from][msg.sender] = allowances_[_from][msg.sender] - _value; // overflow not possible
        }

        balancesHistory_[_from].addCheckpoint(
            block.number,
            previousBalanceFrom - _value // overflow not possible
        );

        balancesHistory_[_to].addCheckpoint(
            block.number,
            add(
                balanceOfAt(_to, block.number),
                _value
            )
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    function _getBlockNumber()
        internal
        view
        returns (uint256)
    {
        return block.number;
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function add(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 c)
    {
        require((c = x + y) >= x, "addition-overflow");
    }

    function sub(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 c)
    {
        require((c = x - y) <= x, "subtraction-overflow");
    }

    function mul(
        uint256 a,
        uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        require((c = a * b) / a == b, "multiplication-overflow");
    }

    function div(
        uint256 a,
        uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        require(b != 0, "division by zero");
        c = a / b;
    }
}