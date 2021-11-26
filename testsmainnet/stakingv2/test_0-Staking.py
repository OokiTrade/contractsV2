#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def testStake_UnStake(requireMainnetFork, STAKINGv2, BZX,  BZRX, vBZRX, iOOKI, OOKI, OOKI_ETH_LP, SUSHI_ROUTER, accounts):

    user1 = accounts[1]
    user2 = accounts[2]

    # approvals
    OOKI.approve(iOOKI, 2**256-1, {"from": user1})
    OOKI.approve(STAKINGv2, 2**256-1, {"from": user1})
    iOOKI.approve(STAKINGv2, 2**256-1, {"from": user1})
    vBZRX.approve(STAKINGv2, 2**256-1, {"from": user1})
    OOKI_ETH_LP.approve(STAKINGv2, 2**256-1, {"from": user1})

    # mint OOKI
    OOKI.mint(user1, 1000 * 1e18, {"from": OOKI.owner()})

    # mint iOOKI
    iOOKI.mint(user1, 100*1e18, {"from": user1})

    # mint OOKI_ETH_LP
    OOKI.approve(SUSHI_ROUTER, 2**256-1, {"from": user1})
    SUSHI_ROUTER.addLiquidityETH(OOKI, 100*1e18, 0, 0, user1, chain.time()+ 1000, {"from": user1, "value": Wei("0.0005 ether")})

    # mint some vBZRX
    vBZRX.transferFrom("0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", user1, 100 *
                       1e18, {"from": "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"})

    # STAKINGv2.stake([OOKI, iOOKI, vBZRX, OOKI_ETH_LP],
    #                 [
    #                     100*1e18,
    #                     iOOKI.balanceOf(user1),
    #                     vBZRX.balanceOf(user1),
    #                     OOKI_ETH_LP.balanceOf(user1)
    # ], {"from": user1})

    STAKINGv2.stake([OOKI],[OOKI.balanceOf(user1)], {"from": user1})
    assert False
