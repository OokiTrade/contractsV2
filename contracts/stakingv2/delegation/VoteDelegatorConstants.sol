/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../../interfaces/IStakingV2.sol";

contract VoteDelegatorConstants {
    address internal constant ZERO_ADDRESS = address(0);

    IStakingV2 staking; // TODO this is just for testing = IStakingV2(0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4);

    // TODO for testing DON'T deploy like that !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function setStaking(address _staking) public {
        staking = IStakingV2(_staking);
    }

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}
