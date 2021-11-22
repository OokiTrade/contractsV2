/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../StakingStateV2.sol";
import "../../governance/PausableGuardian.sol";
import "./Common.sol";
import "../../governance/GovernorBravoInterfaces.sol";
import "../../staking/StakingVoteDelegator.sol";

contract Rewards is StakingStateV2, PausableGuardian {
    function initialize(address target) external onlyOwner {
        // _setTarget(this.votingFromStakedBalanceOf.selector, target);
    }



}
