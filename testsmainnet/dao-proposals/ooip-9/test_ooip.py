#!/usr/bin/python3

import pytest
from brownie import *
import pdb


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() ==
            "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def DAO(GovernorBravoDelegate):
    return Contract.from_abi("governorBravoDelegator", address="0x3133b4f4dcffc083724435784fefad510fa659c6", abi=GovernorBravoDelegate.abi)


@pytest.fixture(scope="module")
def TIMELOCK(Timelock, accounts):
    return Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi, owner=accounts[0])


@pytest.fixture(scope="module")
def iLINK(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iLINK", address="0x463538705E7d22aA7f03Ebf8ab09B067e1001B54", abi=LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDT", address="0x7e9997a38A439b2be7ed9c9C4628391d3e055D48", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iWBTC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iWBTC", address="0x2ffa85f655752fB2aCB210287c60b9ef335f5b6E", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iWETH(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iWETH", address="0xB983E01458529665007fF7E0CDdeCDB74B967Eb6", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def LINK(accounts, TestToken):
    return Contract.from_abi("iUSDC", address="0x514910771AF9Ca656af840dff83E8264EcF986CA", abi=TestToken.abi)

@pytest.fixture(scope="module")
def BZX(interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)

@pytest.fixture(scope="module")
def USDT(TestToken):
    return Contract.from_abi("USDT", address="0xdAC17F958D2ee523a2206206994597C13D831ec7", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(TestToken):
    return Contract.from_abi("USDC", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi)

@pytest.fixture(scope="module")
def WBTC(TestToken):
    return Contract.from_abi("WBTC", address="0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", abi=TestToken.abi)

@pytest.fixture(scope="module")
def WETH(TestToken):
    return Contract.from_abi("WETH", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    


def testGovernanceProposal(requireMainnetFork, accounts, DAO, TIMELOCK, iLINK, iUSDC, LINK):
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"


    
    # exec(open("./scripts/dao-proposals/OOIP-8-itoken-collateral/proposal.py").read())

    proposalCount = DAO.proposalCount()
    proposal = DAO.proposals(proposalCount)
    id = proposal[0]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]

    assert DAO.state.call(id) == 0
    chain.mine(startBlock - chain.height + 1)
    assert DAO.state.call(id) == 1

    tx = DAO.castVote(id, 1, {"from": proposerAddress})
    tx = DAO.castVote(id, 1, {"from": voter1})
    tx = DAO.castVote(id, 1, {"from": voter2})

    assert DAO.state.call(id) == 1

    chain.mine(endBlock - chain.height)
    assert DAO.state.call(id) == 1
    chain.mine()
    assert DAO.state.call(id) == 4

    DAO.queue(id, {"from": proposerAddress})

    proposal = DAO.proposals(proposalCount)
    eta = proposal[2]
    chain.sleep(eta - chain.time())
    chain.mine()

    
    DAO.execute(id, {"from": proposerAddress})

    trader = accounts[4]
    LINK.transfer(trader, 100e18, {"from": "0x0D4f1ff895D12c34994D6B65FaBBeEFDc1a9fb39"})
    LINK.approve(iLINK, 2**256-1, {"from": trader})
    iLINK.mint(trader, 100e18, {'from': trader})
    chain.mine()
    LINK.approve(iUSDC, 2**256-1, {"from": trader})
    iLINK.approve(iUSDC, 2**256-1, {"from": trader})
    txBorrow = iUSDC.borrow("", 10e6, 7884000, 1e18, iLINK.address, trader, trader, b"", {'from': trader})

    assert False



def testITotokenCollateral(requireMainnetFork, accounts, DAO, TIMELOCK, iLINK, iUSDT, iUSDC, iWBTC, iWETH, LINK, USDT, USDC, WBTC, WETH, BZX, LoanSettings, LoanOpenings, GUARDIAN_MULTISIG):
    lo = accounts[0].deploy(LoanOpenings)
    ls = accounts[0].deploy(LoanSettings)
    BZX.replaceContract(lo, {"from": BZX.owner()})
    BZX.replaceContract(ls, {"from": BZX.owner()})

    loanParams = BZX.getDefaultLoanParams(USDC ,USDT, True)
    loanParamsIToken = BZX.getDefaultLoanParams(USDC ,iUSDT, True)
    assert loanParams[1] == loanParamsIToken[1]
    assert loanParams[2] == loanParamsIToken[2]
    assert loanParams[3] == loanParamsIToken[3]
    assert loanParams[4] == USDT
    assert loanParamsIToken[4] == iUSDT
    assert loanParams[5] == loanParamsIToken[5]
    assert loanParams[6] == loanParamsIToken[6]
    assert loanParams[7] == loanParamsIToken[7]

    
    

    BZX.migrateLoanParamsList(iUSDT, 0, 100, {"from": BZX.owner()})
    BZX.migrateLoanParamsList(iUSDC, 0, 100, {"from": BZX.owner()})

    loanParams = BZX.getDefaultLoanParams(USDC ,USDT, False)
    loanParamsIToken = BZX.getDefaultLoanParams(USDC ,iUSDT, False)

    assert loanParamsIToken[0] == "0x0000000000000000000000000000000000000000000000000000000000000000"
    assert loanParamsIToken[1] == False
    assert loanParamsIToken[2] == "0x0000000000000000000000000000000000000000"
    assert loanParamsIToken[3] == "0x0000000000000000000000000000000000000000"
    assert loanParamsIToken[4] == "0x0000000000000000000000000000000000000000"
    assert loanParamsIToken[5] == 0
    assert loanParamsIToken[6] == 0
    assert loanParamsIToken[7] == 0

    assert loanParams[0] != "0x0000000000000000000000000000000000000000000000000000000000000000"
    assert loanParams[1] == True
    assert loanParams[2] == iUSDC
    assert loanParams[3] == USDC
    assert loanParams[4] == USDT
    assert loanParams[5] != 0
    assert loanParams[6] != 0
    assert loanParams[7] != 0
    assert True