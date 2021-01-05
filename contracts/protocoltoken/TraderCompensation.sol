/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../interfaces/IERC20.sol";
import "../openzeppelin/Ownable.sol";


contract TraderCompensation is Ownable {

    // mainnet
    IERC20 public constant vBZRX = IERC20(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);

    // kovan
    //IERC20 public constant vBZRX = IERC20(0x6F8304039f34fd6A6acDd511988DCf5f62128a32);

    uint256 public optinStartTimestamp;
    uint256 public optinEndTimestamp;
    uint256 public claimStartTimestamp;
    uint256 public claimEndTimestamp;

    bool public isActive;
    uint256 public vBZRXDistributed;

    mapping (address => uint256) public whitelist;
    mapping (address => bool) public optinlist;

    constructor(
        uint256 _optinDuration,
        uint256 _claimDuration)
        public
    {
        setTimestamps(
            _getTimestamp(),
            _getTimestamp() + _optinDuration,
            _getTimestamp() + _optinDuration + _claimDuration
        );

        isActive = true;
    }

    function optin()
        external
    {
        require(_getTimestamp() < optinEndTimestamp, "opt-in has ended");
        optinlist[msg.sender] = true;
    }

    function claim()
        external
    {
        require(_getTimestamp() >= claimStartTimestamp, "claim not started");
        require(_getTimestamp() < claimEndTimestamp, "claim has ended");

        uint256 whitelistAmount = whitelist[msg.sender];
        require(isActive && whitelistAmount != 0, "unauthorized");
        require(optinlist[msg.sender], "no opt-in found");

        vBZRX.transfer(
            msg.sender,
            whitelistAmount
        );

        // overflow condition cannot be reached since the above will throw for bad amounts
        vBZRXDistributed += whitelistAmount;
        whitelist[msg.sender] = 0;
    }

    function setWhitelist(
        address[] memory addrs,
        uint256[] memory amounts)
        public
        onlyOwner
    {
        require(addrs.length == amounts.length, "count mismatch");

        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = amounts[i];
        }
    }

    function setOptin(
        address addr,
        bool val)
        public
        onlyOwner
    {
        optinlist[addr] = val;
    }

    function setActive(
        bool _isActive)
        public
        onlyOwner
    {
        isActive = _isActive;
    }

    function setTimestamps(
        uint256 _optinStartTimestamp,
        uint256 _optinEndTimestamp,
        uint256 _claimEndTimestamp)
        public
        onlyOwner
    {
        require(_optinEndTimestamp > _optinStartTimestamp && _claimEndTimestamp > _optinEndTimestamp, "invalid params");
        optinStartTimestamp = _optinStartTimestamp;
        optinEndTimestamp = _optinEndTimestamp;
        claimStartTimestamp = _optinEndTimestamp;
        claimEndTimestamp = _claimEndTimestamp;
    }

    function withdrawVBZRX(
        uint256 _amount)
        public
        onlyOwner
    {
        uint256 balance = vBZRX.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        if (_amount != 0) {
            vBZRX.transfer(
                msg.sender,
                _amount
            );
        }
    }

    function canOptin(
        address _user)
        external
        view
        returns (bool)
    {
        return _getTimestamp() < optinEndTimestamp &&
            !optinlist[_user] &&
            whitelist[_user] != 0 &&
            isActive;
    }

    function claimable(
        address _user)
        external
        view
        returns (uint256)
    {
        uint256 whitelistAmount = whitelist[_user];
        if (whitelistAmount != 0 &&
            _getTimestamp() >= claimStartTimestamp &&
            _getTimestamp() < claimEndTimestamp &&
            optinlist[_user] &&
            isActive) {
            return whitelistAmount;
        }
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}
