#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract



def testStake_Sushi(requireMainnetFork, STAKINGv2, BZX,  BZRX, vBZRX, iOOKI, OOKI, OOKI_ETH_LP, SUSHI_ROUTER, accounts, SUSHI_CHEF, SUSHI):
    account1 = accounts[9]
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"
    account3 = accounts[8]
    OOKI_ETH_LP.approve(STAKINGv2, 2**256-1, {"from": account3})
    OOKI_ETH_LP.approve(STAKINGv2, 2**256-1, {"from": account1})
    OOKI.mint(account3, 1000 * 1e18, {"from": OOKI.owner()})
    OOKI.approve(SUSHI_ROUTER, 2**256-1, {"from": account3})
    SUSHI_ROUTER.addLiquidityETH(OOKI, 100*1e18, 0, 0, account3, chain.time() + 1000, {"from": account3, "value": Wei("0.0005 ether")})
    lpBalanceBefore = SUSHI_CHEF.userInfo(335,STAKINGv2)[0]
    stakeAmount = OOKI_ETH_LP.balanceOf(account3)
    STAKINGv2.stake([OOKI_ETH_LP], [stakeAmount], {'from': account3})

    assert lpBalanceBefore + stakeAmount == SUSHI_CHEF.userInfo(335,STAKINGv2)[0]

    lpBalanceBefore = SUSHI_CHEF.userInfo(335,STAKINGv2)[0]
    STAKINGv2.claimSushi({'from': account1}) # Triggers sushi send rewards to staking
    assert lpBalanceBefore == SUSHI_CHEF.userInfo(335,STAKINGv2)[0]

    STAKINGv2.stake([OOKI_ETH_LP], [OOKI_ETH_LP.balanceOf(account3)], {'from': account3})
    chain.mine(1000)
    initialPendingSushi = STAKINGv2.earned(account3)[4]
    poolShare = STAKINGv2.balanceOfByAsset(OOKI_ETH_LP, account3)/STAKINGv2.totalSupplyByAsset(OOKI_ETH_LP)
    sushiShare =  initialPendingSushi/SUSHI_CHEF.pendingSushi(335,STAKINGv2)

    assert (int)(poolShare*100) == (int)(sushiShare * 100)
    sushiBalanceStaking = SUSHI.balanceOf(STAKINGv2)
    sushiBalance1 = SUSHI.balanceOf(account3)
    STAKINGv2.claimSushi({'from': account3})
    sushiBalance = SUSHI.balanceOf(account3) - sushiBalance1
    assert (initialPendingSushi/sushiBalance) > 0.99
    chain.mine(100);
    assert initialPendingSushi > STAKINGv2.earned(account3)[4]
    assert STAKINGv2.earned(account3)[4] > 0



    chain.mine()
    assert STAKINGv2.earned(account3)[4] == STAKINGv2.earned.call(account3)[4]

    lpBalanceBefore = SUSHI_CHEF.userInfo(335,STAKINGv2)[0]
    STAKINGv2.unstake([OOKI_ETH_LP], [stakeAmount], {'from': account3})
    assert lpBalanceBefore - stakeAmount == SUSHI_CHEF.userInfo(335,STAKINGv2)[0]

    OOKI_ETH_LP.transfer(account1, stakeAmount, {'from': account3})
    pendingBefore1 = STAKINGv2.earned(account1)[4]
    STAKINGv2.stake([OOKI_ETH_LP], [stakeAmount], {'from': account1})
    chain.mine(10)
    pendingBefore2 = STAKINGv2.earned(account1)[4]
    assert pendingBefore2 > pendingBefore1

    STAKINGv2.unstake([OOKI_ETH_LP], [1e18], {'from': account1})
    pendingBefore3 = STAKINGv2.earned(account1)[4]
    assert pendingBefore3 > pendingBefore2
    sushiBalanceBefore = SUSHI.balanceOf(account1)
    STAKINGv2.claimAltRewards({'from': account1})
    assert SUSHI.balanceOf(account1) > sushiBalanceBefore

    chain.mine(1000)
    pendingBefore1 = STAKINGv2.earned(account3)[4]
    sushiBalanceBefore1 = SUSHI.balanceOf(account3);
    sushiBalanceBefore2 = SUSHI.balanceOf(STAKINGv2);
    STAKINGv2.claimSushi({'from': account3})
    assert pendingBefore1/(SUSHI.balanceOf(account3) - sushiBalanceBefore1) > 0.99

    assert True