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
    return Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi)


@pytest.fixture(scope="module")
def OOKI(accounts, TestToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=TestToken.abi)


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
def CRVUSD(TestToken):
    return Contract.from_abi("CRVUSD", address="0xf71040d20Cc3FFBb28c1abcEF46134C7936624e0", abi=TestToken.abi)


@pytest.fixture(scope="module")
def WBTC(TestToken):
    return Contract.from_abi("WBTC", address="0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", abi=TestToken.abi)

@pytest.fixture(scope="module")
def WETH(TestToken):
    return Contract.from_abi("WETH", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    
@pytest.fixture(scope="module")
def INFRASTRUCTURE_MULTISIG():
    return "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"

def testGovernanceProposal(requireMainnetFork, accounts, DAO, TIMELOCK, iUSDC, OOKI, interface, INFRASTRUCTURE_MULTISIG, USDC, USDT,  BZX, iUSDT, TokenRegistry):
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    voter2 = "0xE9d5472Cc0107938bBcaa630c2e4797F75A2D382"


    exec(open("./scripts/dao-proposals/OOIP-20-crvusd/proposal.py").read())

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
    exec(open("./scripts/env/set-eth.py").read())
    acc = accounts[0]
    crvUSD.approve(icrvUSD, 2**256-1, {'from': acc})
    crvUSD.mint(acc, 20000e18, {'from': "0xFF051db87ADFb0bE398016EE5C68280ad49F1Fd8"})
    icrvUSD.mint(acc, 1000e18, {'from': acc})
    assert  history[-1].status.name == 'Confirmed'

    USDC.transfer(acc, 10000e6, {'from': '0x915dA56c5995EAaf66fd06BA3AeD62a4D3BD011A'})
    USDC.approve(icrvUSD, 2**256-1, {'from': acc})
    icrvUSD.borrow("", 50e18, 0, 110e6, USDC, acc, acc, b"", {'from': acc})
    assert  history[-1].status.name == 'Confirmed'

    crvUSD.approve(SUSHI_ROUTER, 2**256-1, {'from': acc})
    SUSHI_ROUTER.addLiquidityETH(crvUSD, 1000e18, 1000e18, 0.6e18, acc, chain.time()+10000, {'from': acc, 'value': 0.6e18})
    icrvUSD.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10000000000000000, '0x0000000000000000000000000000000000000000', acc, b'', {'from': acc, 'value': 10000000000000000})
    assert  history[-1].status.name == 'Confirmed'

    USDC.approve(SUSHI_ROUTER, 2**256-1, {'from': acc})
    SUSHI_ROUTER.addLiquidity(crvUSD, USDC, 1000e18, 1000e6, 1000e18, 1000e6, acc, chain.time() + 1000, {'from': acc})
    icrvUSD.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e6, USDC, acc, b'', {'from': acc})
    assert  history[-1].status.name == 'Confirmed'

    crvUSD.approve(iUSDC, 2**256-1, {'from': acc})
    icrvUSD.approve(iUSDC, 2**256-1, {'from': acc})
    iUSDC.borrow("", 50e6, 0, 100e18, crvUSD, acc, acc, b"", {'from': acc})
    assert  history[-1].status.name == 'Confirmed'
    iUSDC.borrow("", 50e6, 0, 100e18, icrvUSD, acc, acc, b"", {'from': acc})
    assert  history[-1].status.name == 'Confirmed'
    iUSDC.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10000000000000000, '0x0000000000000000000000000000000000000000', acc, b'', {'from': acc, 'value': 10000000000000000})
    assert  history[-1].status.name == 'Confirmed'
    iUSDC.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e18, crvUSD, acc, b'', {'from': acc})
    assert  history[-1].status.name == 'Confirmed'

    iUSDC.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e18, icrvUSD, acc, b'', {'from': acc})
    assert  history[-1].status.name == 'Confirmed'

    assert False



