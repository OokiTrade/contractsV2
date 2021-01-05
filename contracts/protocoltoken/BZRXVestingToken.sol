/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/Ownable.sol";
import "./CheckpointingToken.sol";


contract BZRXVestingToken is CheckpointingToken, Ownable {

    event Claim(
        address indexed owner,
        uint256 value
    );

    string public constant name = "bZx Vesting Token";
    string public constant symbol = "vBZRX";
    uint8 public constant decimals = 18;

    uint256 public constant cliffDuration =                  15768000; // 86400 * 365 * 0.5
    uint256 public constant vestingDuration =               126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff_ =  110376000; // 86400 * 365 * 3.5

    uint256 public constant vestingStartTimestamp =         1594648800; // start_time
    uint256 public constant vestingCliffTimestamp =         vestingStartTimestamp + cliffDuration;
    uint256 public constant vestingEndTimestamp =           vestingStartTimestamp + vestingDuration;
    uint256 public constant vestingLastClaimTimestamp =     vestingEndTimestamp + 86400 * 365;

    uint256 public totalClaimed; // total claimed since start

    //IERC20 public constant BZRX = IERC20(0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87); // testnet
    IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3); // mainnet
    //IERC20 public constant BZRX = IERC20(0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2); // kovan

    uint256 internal constant startingBalance_ = 889389933e18; // 889,389,933 BZRX

    Checkpointing.History internal totalSupplyHistory_;

    mapping (address => uint256) internal lastClaimTime_;
    mapping (address => uint256) internal userTotalClaimed_;

    bool internal isInitialized_;


    // sets up vesting and deposits BZRX
    function initialize()
        external
    {
        require(!isInitialized_, "already initialized");

        balancesHistory_[msg.sender].addCheckpoint(_getBlockNumber(), startingBalance_);
        totalSupplyHistory_.addCheckpoint(_getBlockNumber(), startingBalance_);

        emit Transfer(
            address(0),
            msg.sender,
            startingBalance_
        );

        BZRX.transferFrom(
            msg.sender,
            address(this),
            startingBalance_
        );

        isInitialized_ = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        _claim(_from);
        if (_from != _to) {
            _claim(_to);
        }

        return super.transferFrom(
            _from,
            _to,
            _value
        );
    }

    // user can claim vested BZRX
    function claim()
        public
    {
        _claim(msg.sender);
    }

    // user can burn remaining vBZRX tokens once fully vested; unclaimed BZRX with be withdrawn
    function burn()
        external
    {
        require(_getTimestamp() >= vestingEndTimestamp, "not fully vested");

        _claim(msg.sender);

        uint256 _blockNumber = _getBlockNumber();
        uint256 balanceBefore = balanceOfAt(msg.sender, _blockNumber);
        balancesHistory_[msg.sender].addCheckpoint(_blockNumber, 0);
        totalSupplyHistory_.addCheckpoint(_blockNumber, totalSupplyAt(_blockNumber) - balanceBefore); // overflow not possible

        emit Transfer(
            msg.sender,
            address(0),
            balanceBefore
        );
    }

    // funds unclaimed one year after vesting ends (5 years) can be rescued
    function rescue(
        address _receiver,
        uint256 _amount)
        external
        onlyOwner
    {
        require(_getTimestamp() > vestingLastClaimTimestamp, "unauthorized");

        BZRX.transfer(
            _receiver,
            _amount
        );
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupplyAt(_getBlockNumber());
    }

    function totalSupplyAt(
        uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        return totalSupplyHistory_.getValueAt(_blockNumber);
    }

    // total that has vested, but has not yet been claimed by a user
    function vestedBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        uint256 lastClaim = lastClaimTime_[_owner];
        if (lastClaim < _getTimestamp()) {
            return _totalVested(
                balanceOfAt(_owner, _getBlockNumber()),
                lastClaim
            );
        }
    }

    // total that has not yet vested
    function vestingBalanceOf(
        address _owner)
        public
        view
        returns (uint256 balance)
    {
        balance = balanceOfAt(_owner, _getBlockNumber());
        if (balance != 0) {
            uint256 lastClaim = lastClaimTime_[_owner];
            if (lastClaim < _getTimestamp()) {
                balance = sub(
                    balance,
                    _totalVested(
                        balance,
                        lastClaim
                    )
                );
            }
        }
    }

    // total that has been claimed by a user
    function claimedBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return userTotalClaimed_[_owner];
    }

    // total vested since start (claimed + unclaimed)
    function totalVested()
        external
        view
        returns (uint256)
    {
        return _totalVested(startingBalance_, 0);
    }

    // total unclaimed since start
    function totalUnclaimed()
        external
        view
        returns (uint256)
    {
        return sub(
            _totalVested(startingBalance_, 0),
            totalClaimed
        );
    }

    function _claim(
        address _owner)
        internal
    {
        uint256 vested = vestedBalanceOf(_owner);
        if (vested != 0) {
            userTotalClaimed_[_owner] = add(userTotalClaimed_[_owner], vested);
            totalClaimed = add(totalClaimed, vested);

            BZRX.transfer(
                _owner,
                vested
            );

            emit Claim(
                _owner,
                vested
            );
        }

        lastClaimTime_[_owner] = _getTimestamp();
    }

    function _totalVested(
        uint256 _proportionalSupply,
        uint256 _lastClaimTime)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimeForVesting = _getTimestamp();

        if (currentTimeForVesting <= vestingCliffTimestamp ||
            _lastClaimTime >= vestingEndTimestamp ||
            currentTimeForVesting > vestingLastClaimTimestamp) {
            // time cannot be before vesting starts
            // OR all vested token has already been claimed
            // OR time cannot be after last claim date
            return 0;
        }
        if (_lastClaimTime < vestingCliffTimestamp) {
            // vesting starts at the cliff timestamp
            _lastClaimTime = vestingCliffTimestamp;
        }
        if (currentTimeForVesting > vestingEndTimestamp) {
            // vesting ends at the end timestamp
            currentTimeForVesting = vestingEndTimestamp;
        }

        uint256 timeSinceClaim = sub(currentTimeForVesting, _lastClaimTime);
        return mul(_proportionalSupply, timeSinceClaim) / vestingDurationAfterCliff_; // will never divide by 0
    }
}