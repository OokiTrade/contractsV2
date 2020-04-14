#!/usr/bin/python3

from brownie import *
from brownie import Contract

import shared

def main():
    deployProtocol()
    deployTestLoan()

def deployProtocol():
    global bzx
    global settings
    global tokens
    
    bzx = accounts[0].deploy(bZxProtocol)
    settings = accounts[0].deploy(ProtocolSettings)

    sigs = []
    for s in shared.FuncSigs().values():
        sigs.append(s)
    targets = [settings.address] * len(sigs)
    bzx.setTargets(sigs, targets)

    settings = Contract("ProtocolSettings", address=bzx.address, abi=settings.abi, owner=accounts[0])

    tokens = []
    tokens.append(accounts[0].deploy(TestToken, "Token0", "Token0", 18, 1e21))
    tokens.append(accounts[0].deploy(TestToken, "Token1", "Token1", 18, 1e21))

def deployTestLoan():
    global bzx
    global tokens

    if bzx is None:
        raise ValueError("protocol not deployed")
    
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": shared.Constants()["ZERO_ADDRESS"],
        "loanToken": tokens[0].address,
        "collateralToken": tokens[1].address,
        "initialMargin": Wei("50 ether"),
        "maintenanceMargin": Wei("15 ether"),
        "maxLoanDuration": "2419200"
    }
    tx = settings.addLoanParams([list(loanParams.values())])

    loanParamsId = tx.events["LoanParamsIdSetup"][0]["id"]
    print(loanParamsId)