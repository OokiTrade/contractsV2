#!/usr/bin/python3

import pytest

from brownie import *


def test_ibzrx_pool_rewards(requireFork,BZX, masterChef, FeeExtractAndDistribute_BSC, Proxy_0_5, LoanTokenLogicStandard):

    deployer = accounts.at(masterChef.owner(), True)

    SWEEP_FEES = Contract.from_abi("SWEEP_FEES", BZX.feesController(), FeeExtractAndDistribute_BSC.abi)
    iBZRX = Contract.from_abi("iBZRX", "0xA726F2a7B200b03beB41d1713e6158e0bdA8731F", LoanTokenLogicStandard.abi)

    sweepImpl = deployer.deploy(FeeExtractAndDistribute_BSC)
    sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
    sweepProxy.replaceImplementation(sweepImpl, {"from": deployer})

    IBZRX_POOL_PID = 5
    GOV_POOL_PID = 7

    SWEEP_FEES.togglePause(False, {"from": deployer})
 
    account = "0x5edd6b56f827549a84952dbc79327876d410c22b"
    account = accounts.at(account, True)

    iBZRX.transfer(account, iBZRX.balanceOf("0x1fdca2422668b961e162a8849dc0c2feadb58915"), {'from': "0x1fdca2422668b961e162a8849dc0c2feadb58915"})
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