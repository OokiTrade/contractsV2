#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def testStake_UnStakeMultiuser(requireMainnetFork, STAKINGv2, BZX,  BZRX, vBZRX, iOOKI, OOKI, OOKI_ETH_LP, SUSHI_ROUTER, POOL3_GAUGE, CRV3, BZRXv2_CONVERTER, accounts):

    user1 = accounts[1]
    user2 = accounts[2]

    OOKI.mint(accounts[0], 100000 * 1e18, {"from": OOKI.owner()})
    OOKI.approve(STAKINGv2, 2**256-1, {"from": accounts[0]})

    for user in [user1, user2]:
        # approvals
        OOKI.approve(iOOKI, 2**256-1, {"from": user})
        OOKI.approve(STAKINGv2, 2**256-1, {"from": user})
        iOOKI.approve(STAKINGv2, 2**256-1, {"from": user})
        vBZRX.approve(STAKINGv2, 2**256-1, {"from": user})
        OOKI_ETH_LP.approve(STAKINGv2, 2**256-1, {"from": user})

        # mint OOKI
        OOKI.mint(user, 1000 * 1e18, {"from": OOKI.owner()})

        # mint iOOKI
        iOOKI.mint(user, 100*1e18, {"from": user})

        # mint OOKI_ETH_LP
        OOKI.approve(SUSHI_ROUTER, 2**256-1, {"from": user})
        SUSHI_ROUTER.addLiquidityETH(OOKI, 100*1e18, 0, 0, user, chain.time() + 1000, {"from": user, "value": Wei("0.0005 ether")})

        # mint some vBZRX
        vBZRX.transferFrom("0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", user, 100 *
                           1e18, {"from": "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"})

        STAKINGv2.stake([OOKI, iOOKI, vBZRX, OOKI_ETH_LP],
                        [
                            100*1e18,
                            iOOKI.balanceOf(user),
                            vBZRX.balanceOf(user),
                            OOKI_ETH_LP.balanceOf(user)
        ], {"from": user})

        # since no rewards zero rewards
        assert STAKINGv2.earned(user) == (0, 0, 0, 0, 0)

    # we wait some time so that difference in staking time aren't that substantial
    chain.mine(100)

    # sending rewards, approximately each account has to get half = 500
    STAKINGv2.addRewards(1000*1e18, 0, {"from": accounts[0]})
    earned1 = STAKINGv2.earned(user1)
    earned2 = STAKINGv2.earned(user2)
    chain.mine()

    assert earned1[0] > 500*1e18
    assert earned2[0] > 500*1e18

    # this checks claim(restake)
    user1BalanceBefore = OOKI.balanceOf(user1)
    user2BalanceBefore = OOKI.balanceOf(user2)
    STAKINGv2.claim(True, {"from": user1})
    STAKINGv2.claim(True, {"from": user2})
    assert user1BalanceBefore == OOKI.balanceOf(user1)
    assert user2BalanceBefore == OOKI.balanceOf(user2)
    balance1 = STAKINGv2.balanceOfByAssets(user1)
    balance2 = STAKINGv2.balanceOfByAssets(user2)
    assert balance1[0] > (100*1e18 + earned1[0])
    assert balance2[0] > (100*1e18 + earned2[0])

    STAKINGv2.addRewards(1000*1e18, 0, {"from": accounts[0]})
    chain.mine(100)

    user1BalanceBefore = OOKI.balanceOf(user1)
    user2BalanceBefore = OOKI.balanceOf(user2)
    STAKINGv2.claim(False, {"from": user1})
    STAKINGv2.claim(False, {"from": user2})

    chain.mine(1000)

    STAKINGv2.claim(False, {"from": user1})
    STAKINGv2.claim(False, {"from": user2})

    chain.mine(1000)

    STAKINGv2.unstake([OOKI, vBZRX, iOOKI, OOKI_ETH_LP], [2**256-1, 2**256-1, 2**256-1, 2**256-1], {"from": user1})
    STAKINGv2.unstake([OOKI, vBZRX, iOOKI, OOKI_ETH_LP], [2**256-1, 2**256-1, 2**256-1, 2**256-1], {"from": user2})

    assert BZRX.balanceOf(STAKINGv2) == 0
    assert OOKI.balanceOf(STAKINGv2)/1e18 < 1

    assert False


def testStake_UnStakeSingleUser(requireMainnetFork, STAKINGv2, BZX,  BZRX, vBZRX, iOOKI, OOKI, OOKI_ETH_LP, SUSHI_ROUTER, POOL3_GAUGE, CRV3, BZRXv2_CONVERTER, accounts):

    user1 = accounts[1]
    OOKI.mint(accounts[0], 100000 * 1e18, {"from": OOKI.owner()})
    OOKI.approve(STAKINGv2, 2**256-1, {"from": accounts[0]})

    for user in [user1]:
        # approvals
        OOKI.approve(iOOKI, 2**256-1, {"from": user})
        OOKI.approve(STAKINGv2, 2**256-1, {"from": user})
        iOOKI.approve(STAKINGv2, 2**256-1, {"from": user})
        vBZRX.approve(STAKINGv2, 2**256-1, {"from": user})
        OOKI_ETH_LP.approve(STAKINGv2, 2**256-1, {"from": user})

        # mint OOKI
        OOKI.mint(user, 1000 * 1e18, {"from": OOKI.owner()})

        # mint iOOKI
        iOOKI.mint(user, 100*1e18, {"from": user})

        # mint OOKI_ETH_LP
        OOKI.approve(SUSHI_ROUTER, 2**256-1, {"from": user})
        SUSHI_ROUTER.addLiquidityETH(OOKI, 100*1e18, 0, 0, user, chain.time() + 1000, {"from": user, "value": Wei("0.0005 ether")})

        # mint some vBZRX
        vBZRX.transferFrom("0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", user, 100 *
                           1e18, {"from": "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"})

        STAKINGv2.stake([
            OOKI,
            # iOOKI,
            vBZRX,
            # OOKI_ETH_LP
        ],
            [
            100*1e18,
            # iOOKI.balanceOf(user),
            vBZRX.balanceOf(user),
            # OOKI_ETH_LP.balanceOf(user)
        ], {"from": user})

        # since no rewards zero rewards
        assert STAKINGv2.earned(user) == (0, 0, 0, 0, 0)

    # we wait some time so that difference in staking time aren't that substantial
    chain.mine(100)

    # sending rewards, approximately each account has to get half = 500
    STAKINGv2.addRewards(1000*10**18, 0, {"from": accounts[0]})
    earned1 = STAKINGv2.earned(user1)
    # chain.mine()
    assert earned1[0] <=1000*10**18
    # assert earned1[0] > 500*1e18

    # # this checks claim(restake)
    # user1BalanceBefore = OOKI.balanceOf(user1)
    # STAKINGv2.claim(True, {"from": user1})
    # assert user1BalanceBefore == OOKI.balanceOf(user1)
    # balance1 = STAKINGv2.balanceOfByAssets(user1)

    # assert balance1[0] >= (100*1e18 + earned1[0])

    # STAKINGv2.addRewards(1000*1e18, 0, {"from": accounts[0]})
    # chain.mine(100)

    # user1BalanceBefore = OOKI.balanceOf(user1)

    # STAKINGv2.claim(False, {"from": user1})

    # chain.mine(1000)
    # STAKINGv2.claim(False, {"from": user1})
    # # STAKINGv2.claim(False, {"from": user1})

    # # chain.mine(1000)

    # STAKINGv2.unstake([vBZRX], [2**256-1], {"from": user1})
    # STAKINGv2.unstake([OOKI], [2**256-1], {"from": user1})


    assert False
