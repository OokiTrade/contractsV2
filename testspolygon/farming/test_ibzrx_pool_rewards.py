#!/usr/bin/python3

import pytest

from brownie import *


def test_ibzrx_pool_rewards(requireFork, masterChef):

    deployer = accounts.at(masterChef.owner(), True)

    SWEEP_FEES = Contract.from_abi("STAKING", "0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", FeeExtractAndDistribute_Polygon.abi)
    iBZRX = Contract.from_abi("iBZRX", "0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9", LoanTokenLogicStandard.abi)

    IBZRX_POOL_PID = 2

    SWEEP_FEES.togglePause(False, {"from": deployer})



    account = "0xcF7C03cf8bAbeB0a81992B49E326788906F026E0"
    account = accounts.at(account, True)
    

    masterChef.deposit(IBZRX_POOL_PID, iBZRX.balanceOf(account), {"from": account})

    balance = account.balance()
    tokenPrice = iBZRX.tokenPrice() 

    assert  masterChef._pendingAltRewards(IBZRX_POOL_PID, account) == 0

    SWEEP_FEES.sweepFees({"from": accounts[0], "gas_limit": 10000000})
    assert iBZRX.tokenPrice() > tokenPrice

    earnings = masterChef._pendingAltRewards(IBZRX_POOL_PID, account)

    masterChef.claimReward(IBZRX_POOL_PID, {"from": account})
    
    assert balance + earnings == account.balance()
    assert True