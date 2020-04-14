#!/usr/bin/python3

import pytest
from brownie import Contract

@pytest.fixture(scope="module")
def Constants():
    return {
        "ZERO_ADDRESS": "0x0000000000000000000000000000000000000000",
        "ONE_ADDRESS": "0x0000000000000000000000000000000000000001",
    }

@pytest.fixture(scope="module")
def FuncSigs():
    return {
        "setCoreParams": "setCoreParams(address,address,address)",
        "setProtocolManagers": "setProtocolManagers(address[],bool[])",
        
        "setupLoanParams": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256))",
        "setupLoanParams2": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])",
        "disableLoanParams": "disableLoanParams(bytes32[])",
        #"getLoanParams": "getLoanParams(bytes32[])",
        "getLoanParams": "getLoanParams(bytes32)",
        "setupOrder": "setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,bool)",
        "setupOrder2": "setupOrder(uint256,uint256,uint256,uint256,bool)",

        #"openLoanFromPool": "openLoanFromPool(bytes32,bytes32,address[4],uint256[6],bytes)",
        #"setDelegatedManager": "setDelegatedManager(bytes32,address,bool)",
        #"getRequiredCollateral": "getRequiredCollateral(address,address,address,uint256,uint256)",
        #"getBorrowAmount": "getBorrowAmount(address,address,uint256,uint256)",
    }

@pytest.fixture(scope="module")
def bzx(bZxProtocol, accounts):
    return accounts[0].deploy(bZxProtocol)

@pytest.fixture(scope="module")
def settings(ProtocolSettings, FuncSigs, accounts, bzx):

    settings = accounts[0].deploy(ProtocolSettings)

    sigs = []
    for s in FuncSigs.values():
        sigs.append(s)
    targets = [settings.address] * len(sigs)
    bzx.setTargets(sigs, targets)

    return Contract("ProtocolSettings", address=bzx.address, abi=settings.abi, owner=accounts[0])

@pytest.fixture(scope="module")
def loanSettings(LoanSettings, FuncSigs, accounts, bzx):

    loanSettings = accounts[0].deploy(LoanSettings)

    sigs = []
    for s in FuncSigs.values():
        sigs.append(s)
    targets = [settings.address] * len(sigs)
    bzx.setTargets(sigs, targets)

    return Contract("ProtocolSettings", address=bzx.address, abi=settings.abi, owner=accounts[0])

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass
