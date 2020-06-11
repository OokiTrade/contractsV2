#!/usr/bin/python3

import pytest

def test_targetSetup(Constants, bzx):

    sig1 = "testFunction1(address,uint256,bytes)"
    sig2 = "testFunction2(address[],uint256[],bytes[])"

    sigs = [sig1,sig2]
    targets = [Constants["ONE_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(sig1) == Constants["ONE_ADDRESS"]
    assert bzx.getTarget(sig2) == Constants["ONE_ADDRESS"]

    targets = [Constants["ZERO_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(sig1) == Constants["ZERO_ADDRESS"]
    assert bzx.getTarget(sig2) == Constants["ZERO_ADDRESS"]

def test_replaceContract(Constants, bzx, accounts, LoanSettings):

    sig = "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])"
    loanSettings = accounts[0].deploy(LoanSettings)

    bzx.setTargets([sig], [Constants["ZERO_ADDRESS"]])
    assert bzx.getTarget(sig) == Constants["ZERO_ADDRESS"]

    bzx.replaceContract(loanSettings.address)
    assert bzx.getTarget(sig) == loanSettings.address

def test_receivesEther(web3, bzx, accounts):

    assert(web3.eth.getBalance(bzx.address) == 0)
    web3.eth.sendTransaction({ "from": str(accounts[0]), "to": bzx.address, "value": 10000, "gas": "5999" })
    assert(web3.eth.getBalance(bzx.address) == 10000)
