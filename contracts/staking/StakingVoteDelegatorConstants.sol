/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../interfaces/IStaking.sol";


contract StakingVoteDelegatorConstants {
    address constant internal ZERO_ADDRESS = address(0);

    IStaking constant staking = IStaking(0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

}
