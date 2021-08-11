/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
import "../../../interfaces/IBZx.sol";

interface IStakingPartial {

    function pendingSushiRewards(address _user)
        external
        view
        returns (uint256);

    function currentFeeTokens()
        external
        view
        returns (address[] memory);

    function maxUniswapDisagreement()
        external
        view
        returns (uint256);

    function stakingRewards(address)
        external
        view
        returns (uint256);

    function setStakingRewards(address, uint256)
        external;

    function fundsWallet()
        external
        view
        returns (address);


    function callerRewardDivisor()
        external
        view
        returns (uint256);


    function maxCurveDisagreement()
        external
        view
        returns (uint256);

    function rewardPercent()
        external
        view
        returns (uint256);

    function swapPaths(address path)
        external
        returns (address[] memory);

    function addRewards(uint256 newBZRX, uint256 newStableCoin)
        external;

}
