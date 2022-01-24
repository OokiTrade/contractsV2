/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "../interfaces/IVestingToken.sol";
import "../proxies/0_5/Upgradeable_0_5.sol";
import "../../interfaces/IBZRXv2Converter.sol";
import "../../interfaces/IStakingV2.sol";


contract LockedVesting is Upgradeable_0_5 {
    using SafeMath for uint256;

    IVestingToken public constant vBZRX = IVestingToken(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);
    IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);
    IERC20 public constant OOKI = IERC20(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B);
    IBZRXv2Converter public constant CONVERTER = IBZRXv2Converter(0x6BE9B7406260B6B6db79a1D4997e7f8f5c9D7400);
    IStakingV2 public constant STAKING = IStakingV2(0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4); // update for new staking contract

    //uint256 public totalDeposit;
    //uint256 internal lastClaimTime_;

    constructor() public {
        vBZRX.approve(address(STAKING), uint256(-1));
        BZRX.approve(address(STAKING), uint256(-1));
        OOKI.approve(address(STAKING), uint256(-1));

        BZRX.approve(address(CONVERTER), uint256(-1));
    }

    function stake(address[] memory tokens, uint256[] memory values) external onlyOwner {
        STAKING.stake(tokens, values);
    }

    function unstake(address[] memory tokens, uint256[] memory values) external onlyOwner {
        STAKING.unstake(tokens, values);
    }

    function claim() external onlyOwner {
        vBZRX.claim();
        CONVERTER.convert(msg.sender, IERC20(BZRX).balanceOf(address(this)));
    }

    function claimBZRX() external onlyOwner {
        vBZRX.claim();
        BZRX.transfer(msg.sender, IERC20(BZRX).balanceOf(address(this)));
    }

    function rescue(IERC20 _token) public onlyOwner {
        if (_token != IERC20(vBZRX)) {
            SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
        }
    }

    function rescueEth() public onlyOwner {
        (bool success,) = msg.sender.call.value(address(this).balance)("");
        require(success, "transfer failed");
    }


    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyOwner returns (bytes memory) {
        bytes memory callData;

        bytes4 sig;
        if (bytes(signature).length == 0) {
            bytes4 sig;
            assembly {
                sig := mload(add(data, 32))
            }
            

            expectedRate := mload(add(data, 32))
            
            
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function sendTransaction(address target, bytes memory callData) public onlyOwner {
    {
        if (msg.sender != owner()) {
            address _lowerAdmin;
            address _lowerAdminContract;
            assembly {
                _lowerAdmin := sload(iToken_LowerAdminAddress)
                _lowerAdminContract := sload(iToken_LowerAdminContract)
            }
            require(msg.sender == _lowerAdmin && settingsTarget == _lowerAdminContract);
        }

        address currentTarget = target_;
        target_ = settingsTarget;

        (bool result,) = address(this).call(callData);

        uint256 size;
        uint256 ptr;
        assembly {
            size := returndatasize
            ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) { revert(ptr, size) }
        }

        target_ = currentTarget;

        assembly {
            return(ptr, size)
        }
    }
}


    /*function deposit(uint256 value) external {
        vBZRX.transferFrom(msg.sender, address(this), value);
        totalDeposit += value;
    }

    function withdraw(uint256 value) public {
        uint256 balance = balanceOf[msg.sender];
        if (value > balance) {
            value = balance;
        }
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        vBZRX.transfer(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        emit Withdraw(msg.sender, value);
    }

    function vestedBalanceOf()
        public
        view
        returns (uint256)
    {
        uint256 lastClaim = lastClaimTime_;
        if (lastClaim < block.timestamp) {
            return _totalVested(
                vBZRx.balanceOf(address(this)),
                lastClaim
            );
        }
    }

    function claim() public onlyOwner {
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

        lastClaimTime_[_owner] = block.timestamp;
    }

    function _totalVested(
        uint256 _proportionalSupply,
        uint256 _lastClaimTime)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimeForVesting = block.timestamp;

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
    }*/
}
