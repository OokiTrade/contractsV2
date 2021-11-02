#!/usr/bin/python3

import pytest

from brownie import *


def test_ibzrx_pool_rewards(requireFork, BZRX, masterChef, FeeExtractAndDistribute_Polygon, Proxy_0_5, LoanTokenLogicStandard):

    deployer = accounts.at(masterChef.owner(), True)

    SWEEP_FEES = Contract.from_abi("SWEEP_FEES", "0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", FeeExtractAndDistribute_Polygon.abi)
    iBZRX = Contract.from_abi("iBZRX", "0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9", LoanTokenLogicStandard.abi)

    sweepImpl = deployer.deploy(FeeExtractAndDistribute_Polygon)
    sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
    sweepProxy.replaceImplementation(sweepImpl, {"from": deployer})

    IBZRX_POOL_PID = 2
    GOV_POOL_PID = 0

    SWEEP_FEES.togglePause(False, {"from": deployer})
 
    account = "0x4b8eafcc1c609ce3489e9b209e2fb020077210d0"
    account = accounts.at(account, True)

    iBZRX.transfer(account, iBZRX.balanceOf("0xd39ff512c3e55373a30e94bb1398651420ae1d43"), {'from': "0xd39ff512c3e55373a30e94bb1398651420ae1d43"})
    iBZRX.approve(masterChef, 2**256-1, {'from': account})
    masterChef.deposit(IBZRX_POOL_PID, iBZRX.balanceOf(account), {"from": account})

    balance = account.balance()
    tokenPrice = iBZRX.tokenPrice() 

    assert masterChef.pendingAltRewards(IBZRX_POOL_PID, account) == 0
    assert masterChef.getOptimisedUserInfos(account)[GOV_POOL_PID][3] > 0
    assert masterChef.getOptimisedUserInfos(account)[IBZRX_POOL_PID][3] == 0

    treasury = accounts.at(SWEEP_FEES.treasuryWallet(), True)

    treasuryBalance = treasury.balance()

    tx = SWEEP_FEES.sweepFees({"from": accounts[0], "gas_limit": 10000000, "required_confs": 0})

    assert treasury.balance() > treasuryBalance

    assert iBZRX.tokenPrice() > tokenPrice

    earnings = masterChef.pendingAltRewards(IBZRX_POOL_PID, account)

    assert masterChef.getOptimisedUserInfos(account)[GOV_POOL_PID][3] > 0
    assert masterChef.getOptimisedUserInfos(account)[IBZRX_POOL_PID][3] > 0

    masterChef.claimReward(IBZRX_POOL_PID, {"from": account})
    assert balance + earnings == account.balance()

    masterChef.claimReward(GOV_POOL_PID, {"from": account})
    assert masterChef.getOptimisedUserInfos(account)[GOV_POOL_PID][3] == 0
    assert masterChef.getOptimisedUserInfos(account)[IBZRX_POOL_PID][3] == 0