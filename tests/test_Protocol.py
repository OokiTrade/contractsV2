#!/usr/bin/python3

import pytest

def test_targetSetup(Constants, FuncSigs, bzxproxy):

    sigs = [
        FuncSigs["LoanSettings"]["setupLoanParams"],
        FuncSigs["LoanSettings"]["disableLoanParams"]
    ]
    targets = [Constants["ONE_ADDRESS"]] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

    assert bzxproxy.getTarget(FuncSigs["LoanSettings"]["setupLoanParams"]) == Constants["ONE_ADDRESS"]
    assert bzxproxy.getTarget(FuncSigs["LoanSettings"]["disableLoanParams"]) == Constants["ONE_ADDRESS"]

    targets = [Constants["ZERO_ADDRESS"]] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

    assert bzxproxy.getTarget(FuncSigs["LoanSettings"]["setupLoanParams"]) == Constants["ZERO_ADDRESS"]
    assert bzxproxy.getTarget(FuncSigs["LoanSettings"]["disableLoanParams"]) == Constants["ZERO_ADDRESS"]

def test_receivesEther(web3, bzxproxy, accounts):

    assert(web3.eth.getBalance(bzxproxy.address) == 0)
    web3.eth.sendTransaction({ "from": str(accounts[0]), "to": bzxproxy.address, "value": 10000, "gas": "5999" })
    assert(web3.eth.getBalance(bzxproxy.address) == 10000)

'''
todo setup Interfaces

TODO:
browie: create for all logic functions, but if interface folder
    ref: https://eth-brownie.readthedocs.io/en/stable/api-network.html?highlight=InterfaceContainer%20#brownie.network.contract.InterfaceContainer


'''