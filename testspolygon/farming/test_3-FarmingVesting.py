#!/usr/bin/python3

import pytest

from conftest import initBalance, requireFork
from brownie import chain, reverts


testdata = [
    ('MATIC', 'iMATIC', 8)
]

INITIAL_LP_TOKEN_ACCOUNT_AMOUNT = 10 * 10 ** 18;
GOV_POOL_PID = 0
## GovPool locked
## LPPool locked
@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_Vesting1(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[7]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    lpBalance1 = lpToken.balanceOf(account1)
    startVestinStamp = 1625993882
    vestingDuration = 15768000
    masterChef.setStartVestingStamp(startVestinStamp, {'from': masterChef.owner()});
    masterChef.setVestingDuration(vestingDuration, {'from': masterChef.owner()});


    lpToken.approve(masterChef, 2**256-1, {'from': account1})
    depositAmount = lpBalance1
    # masterChef.set(GOV_POOL_PID, 10000000000, True, {'from': masterChef.owner()})
    # masterChef.set(pid, 10000000000, True, {'from': masterChef.owner()})
    govToken.approve(masterChef, 2**256-1, {'from': account1})
    masterChef.setLocked(pid, True, {'from': masterChef.owner()})
    masterChef.setLocked(GOV_POOL_PID, True, {'from': masterChef.owner()})

    tx1 = masterChef.deposit(pid, depositAmount, {'from': account1})
    chain.mine(blocks=100)

    masterChef.compoundReward(pid,  {'from': account1})
    chain.mine()
    masterChef.compoundReward(GOV_POOL_PID,  {'from': account1})
    chain.mine()
    lockedRewards1 = masterChef.lockedRewards(account1);
    assert lockedRewards1 > 0
    chain.mine(blocks=100)

    assert masterChef.unlockedRewards(account1) > 0
    assert masterChef.lockedRewards(account1) < lockedRewards1
    masterChef.toggleVesting(False,{'from': masterChef.owner()});

    lockedRewards = masterChef.lockedRewards(account1)
    masterChef.toggleVesting(True,{'from': masterChef.owner()});
    assert lockedRewards == 0


def testFarming_Vesting2(requireFork, masterChef):
    lockedAmount = 1000e18
    startVestinStamp = 1625993882
    userStartVestinStamp = 1626013882
    vestingDuration = 15768000
    now = chain.time()

    masterChef.setStartVestingStamp(0, {'from': masterChef.owner()});
    masterChef.setVestingDuration(0, {'from': masterChef.owner()});

    assert masterChef.calculateUnlockedRewards(lockedAmount, now + masterChef.vestingDuration(), 0) == 0
    masterChef.setStartVestingStamp(startVestinStamp, {'from': masterChef.owner()});
    assert masterChef.calculateUnlockedRewards(lockedAmount, now + masterChef.vestingDuration(), 0) == 0

    masterChef.setVestingDuration(vestingDuration, {'from': masterChef.owner()});
    assert masterChef.calculateUnlockedRewards(lockedAmount, now, startVestinStamp) == masterChef.calculateUnlockedRewards(lockedAmount, now, 0)
    assert masterChef.calculateUnlockedRewards(lockedAmount, now, userStartVestinStamp) < masterChef.calculateUnlockedRewards(lockedAmount, now, startVestinStamp)
    assert masterChef.calculateUnlockedRewards(lockedAmount, now + masterChef.vestingDuration(), 0) == lockedAmount
    masterChef.calculateUnlockedRewards(lockedAmount, now + masterChef.vestingDuration()-1, now) < lockedAmount
    masterChef.calculateUnlockedRewards(lockedAmount, now + masterChef.vestingDuration(), now) == lockedAmount

    cliffDuration = now - userStartVestinStamp
    assert masterChef.calculateVestingStartStamp(now, userStartVestinStamp, lockedAmount, lockedAmount/2) == (cliffDuration/2) + userStartVestinStamp
    assert masterChef.calculateVestingStartStamp(now, userStartVestinStamp, lockedAmount, lockedAmount) == (cliffDuration) + userStartVestinStamp
    assert masterChef.calculateVestingStartStamp(now, userStartVestinStamp, lockedAmount, 0) == userStartVestinStamp

def testFarming_Vesting3(requireFork, masterChef, accounts):
    with reverts("Ownable: caller is not the owner"):
        masterChef.setVestingDuration(5 * 365 * 24 * 60 * 60, {'from': accounts[0]});

    with reverts("Ownable: caller is not the owner"):
        masterChef.setStartVestingStamp(1, {'from': accounts[0]});

    now = chain.time()
    masterChef.setStartVestingStamp(now, {'from': masterChef.owner()});
    assert masterChef.startVestingStamp() == now


    vestingDuration = 5 * 365 * 24 * 60 * 60;
    masterChef.setVestingDuration(vestingDuration, {'from':  masterChef.owner()});
    assert masterChef.vestingDuration() == vestingDuration

