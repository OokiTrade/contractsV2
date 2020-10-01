#!/usr/bin/python3
import pytest
from brownie import network, Contract, reverts, Wei


 
@pytest.fixture(scope="module")
def flashLoan(accounts, Flashloan):
    flashLoanProxy = accounts[0].deploy(Flashloan)
    return Contract.from_abi("flashLoanProxy", address=flashLoanProxy,  abi=Flashloan.abi, owner=accounts[0])


def testFlashLoan(flashLoan, accounts):
    tx = flashLoan.flashloan();
    tx.info();
    print("hello")
    assert False




