/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Common.sol";

contract Rewards is Common {
    function initialize(address target) external onlyOwner {
        _setTarget(this.addRewards.selector, target);
        _setTarget(this.getVariableWeights.selector, target);
        _setTarget(this.totalSupplyStored.selector, target);
    }

    // note: anyone can contribute rewards to the contract
    function addRewards(uint256 newBZRX, uint256 newStableCoin) external pausable {
        if (newBZRX != 0 || newStableCoin != 0) {
            _addRewards(newBZRX, newStableCoin);
            if (newBZRX != 0) {
                IERC20(OOKI).transferFrom(msg.sender, address(this), newBZRX);
            }
            if (newStableCoin != 0) {
                curve3Crv.transferFrom(msg.sender, address(this), newStableCoin);
                _depositTo3Pool(newStableCoin);
            }
        }
    }

    function _addRewards(uint256 newBZRX, uint256 newStableCoin) internal {
        (vBZRXWeightStored, iBZRXWeightStored, LPTokenWeightStored) = getVariableWeights();

        uint256 totalTokens = totalSupplyStored();
        require(totalTokens != 0, "nothing staked");
        
        bzrxPerTokenStored = newBZRX.mul(1e36).div(totalTokens).add(bzrxPerTokenStored);

        stableCoinPerTokenStored = newStableCoin.mul(1e36).div(totalTokens).add(stableCoinPerTokenStored);

        lastRewardsAddTime = block.timestamp;

        emit AddRewards(msg.sender, newBZRX, newStableCoin);
    }

    function getVariableWeights()
        public
        view
        returns (
            uint256 vBZRXWeight,
            uint256 iBZRXWeight,
            uint256 LPTokenWeight
        )
    {
        uint256 totalVested = vestedBalanceForAmount(_startingVBZRXBalance, 0, block.timestamp);

        vBZRXWeight = SafeMath.mul(_startingVBZRXBalance - totalVested, 1e18).div(_startingVBZRXBalance); // overflow not possible

        iBZRXWeight = _calcIBZRXWeight();

        uint256 lpTokenSupply = _totalSupplyPerToken[OOKI_ETH_LP];
        if (lpTokenSupply != 0) {
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            uint256 normalizedLPTokenSupply = IERC20(OOKI).totalSupply() - _totalSupplyPerToken[OOKI];

            LPTokenWeight = normalizedLPTokenSupply.mul(1e18).div(lpTokenSupply);
        }
    }

    function _depositTo3Pool(uint256 amount) internal {
        if (amount == 0) curve3PoolGauge.deposit(curve3Crv.balanceOf(address(this)));
        // claiming rewards is at unstake or other
    }

    function totalSupplyStored() public view returns (uint256 supply) {
        supply = _totalSupplyPerToken[vBZRX].mul(vBZRXWeightStored)
            .div(1e17); // OOKI is 10x BZRX

        supply = _totalSupplyPerToken[OOKI].add(supply);

        supply = _totalSupplyPerToken[iOOKI].mul(iBZRXWeightStored).div(1e50).add(supply);

        supply = _totalSupplyPerToken[OOKI_ETH_LP].mul(LPTokenWeightStored).div(1e18).add(supply);
    }
}
