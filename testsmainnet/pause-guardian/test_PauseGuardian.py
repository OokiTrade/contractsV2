#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

@pytest.fixture(scope="class", autouse=True)
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", TestToken.abi)

@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard, LoanToken):
    timelock = "0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc"
    loanTokenLogicStandard = accounts[0].deploy(LoanTokenLogicStandard, timelock)
    loanTokenProxy = Contract.from_abi(name="loanTokenProxy", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanToken.abi)
    loanTokenProxy.setTarget(loanTokenLogicStandard, {'from': timelock})


    return Contract.from_abi("iDAI", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15",  abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def BZX(accounts, interface, LoanMaintenance, LoanOpenings, ProtocolPausableGuardian):
    
    bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi, owner=accounts[0])
    bzxOwner = accounts.at(bzx.owner(), True)
    
    loanMaintenanceImpl = bzxOwner.deploy(LoanMaintenance)
    bzx.replaceContract(loanMaintenanceImpl, {'from': bzxOwner})
    
    loanOpenings = bzxOwner.deploy(LoanOpenings)
    bzx.replaceContract(loanOpenings, {'from': bzxOwner})

    protocolPausableGuardian = bzxOwner.deploy(ProtocolPausableGuardian)
    bzx.replaceContract(protocolPausableGuardian, {'from': bzxOwner})

    return bzx
 

def testPauseGuardianOnIToken(requireMainnetFork, iUSDC, accounts, USDC):
    bzxOwner = "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
    # mint some USDC
    USDC.transfer(accounts[0], 100*1e6, {"from": "0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503"})
    USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
    # checking that normal operation works
    iUSDC.mint(accounts[0], 1e6, {"from": accounts[0]})

    assert iUSDC.getGuardian() == "0x0000000000000000000000000000000000000000"
    
    iUSDC.changeGuardian(accounts[0], {"from": iUSDC.owner()})

    assert iUSDC.getGuardian() == accounts[0]

    with reverts("unauthorized"):
        iUSDC.changeGuardian(accounts[2], {"from": accounts[1]})


    assert iUSDC._isPaused(iUSDC.mint.signature) == False
    iUSDC.toggleFunctionPause(iUSDC.mint.signature, {"from": iUSDC.owner()})
    assert iUSDC._isPaused(iUSDC.mint.signature) == True

    # checking other functions are still false
    assert iUSDC._isPaused(iUSDC.burn.signature) == False

    with reverts("paused"):
        iUSDC.mint(accounts[0], 1e6, {"from": accounts[0]})

    assert True


def testPauseGuardianOnProtocol(requireMainnetFork, BZX, accounts):

    assert BZX.getGuardian() == "0x0000000000000000000000000000000000000000"
    
    with reverts("unauthorized"): # only guardian or owner can change guardian
        BZX.changeGuardian(accounts[0], {'from': accounts[2]})

    BZX.changeGuardian(accounts[1], {'from': BZX.owner()})
    assert BZX.getGuardian() == accounts[1]

    # checking guardian can change guardian
    BZX.changeGuardian(accounts[0], {'from': accounts[1]})
    assert BZX.getGuardian() == accounts[0]

    with reverts("not authorized"): # this means passed pausable check
        BZX.borrowOrTradeFromPool(0, 0, True, 0, [accounts[0],accounts[0],accounts[0],accounts[0]],[0,0,0,0,0], b'')

    with reverts("unauthorized"): # only guardian or owner() can pause 
        BZX.toggleFunctionPause(BZX.borrowOrTradeFromPool.signature, {"from": accounts[1]})

    BZX.toggleFunctionPause(BZX.borrowOrTradeFromPool.signature, {"from": accounts[0]})
    assert True == BZX._isPaused(BZX.borrowOrTradeFromPool.signature)

    with reverts("paused"): # this means not passed pausable check
        BZX.borrowOrTradeFromPool(0, 0, True, 0, [accounts[0],accounts[0],accounts[0],accounts[0]],[0,0,0,0,0], b'')

    with reverts("unauthorized"): # only owner() can unpause
        BZX.toggleFunctionUnPause(BZX.borrowOrTradeFromPool.signature, {"from": accounts[1]})

    BZX.toggleFunctionUnPause(BZX.borrowOrTradeFromPool.signature, {"from": BZX.owner()})
    assert BZX._isPaused(BZX.borrowOrTradeFromPool.signature) == False


    with reverts("not authorized"): # this means passed pausable check
        BZX.borrowOrTradeFromPool(0, 0, True, 0, [accounts[0],accounts[0],accounts[0],accounts[0]],[0,0,0,0,0], b'')
    assert True