#!/usr/bin/python3

import pytest
from brownie import *
import pdb
from eth_abi import encode_abi
from eth_abi.packed import encode_single_packed, encode_abi_packed


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
def OOKI(accounts, TestToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=TestToken.abi)

@pytest.fixture(scope="module")
def PRICE_FEED(PriceFeeds, BZX):
    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)

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
def crvUSD(TestToken):
    return Contract.from_abi("crvUSD", address="0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E", abi=TestToken.abi)
@pytest.fixture(scope="module")
def icrvUSD(TestToken):
    return Contract.from_abi("icrvUSD", address="0x3D87106A93F56ceE890769A808Af62Abc67ECBD3", abi=LoanTokenLogicStandard.abi)

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

def testGovernanceProposal(requireMainnetFork, accounts, DAO, TIMELOCK, iUSDC, PRICE_FEED, interface, INFRASTRUCTURE_MULTISIG, USDC, USDT, crvUSD,icrvUSD, BZX, iUSDT, TokenRegistry, OOKI):
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    voter2 = "0xE9d5472Cc0107938bBcaa630c2e4797F75A2D382"

    exec(open("./scripts/dao-proposals/OOIP-20-iCRVUSD/proposal.py").read())

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

    assert PRICE_FEED.pricesFeeds(crvUSD) == '0xE4Ac87b95FFb28FDCb009009b4eDF949702f1785'

    acc = "0xA920De414eA4Ab66b97dA1bFE9e6EcA7d4219635"
    crvUSD.transfer(accounts[0], 10000e18, {'from': acc})
    assert  history[-1].status.name == 'Confirmed'
    crvUSD.approve(iETH, 2**256-1, {'from': accounts[0]})
    assert  history[-1].status.name == 'Confirmed'
    crvUSD.approve(iUSDT, 2**256-1, {'from': accounts[0]})
    assert  history[-1].status.name == 'Confirmed'
    icrvUSD.approve(iETH, 2**256-1, {'from': accounts[0]})
    assert  history[-1].status.name == 'Confirmed'
    crvUSD.approve(icrvUSD, 2**256-1, {'from': accounts[0]})
    assert  history[-1].status.name == 'Confirmed'
    icrvUSD.mint(accounts[0], 100e18, {'from': accounts[0]})
    assert  history[-1].status.name == 'Confirmed'

    amountOfEthToTrade = int(0.01e18)
    FLAGS_DEX_SELECTOR_FLAG = 2
    FEE = 0.1
    LEAVERAGE = 3
    route = encode_abi_packed(['address','uint24','address','uint24','address'],[WETH.address,500,USDC.address, 500, crvUSD.address])
    swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,chain.time()+10000,100,100)]])
    openSendOut = encode_abi(['uint128','bytes[]'],[2,[encode_abi(['uint256','bytes'],[2,swap_payload])]])
    iETH.marginTrade(0000000000000000000000000000000000000000000000000000000000000000, (LEAVERAGE-1)*1e18, amountOfEthToTrade, 0, crvUSD, accounts[0], openSendOut, {'from':accounts[0],'value':amountOfEthToTrade})
    assert  history[-1].status.name == 'Confirmed'
    assert False



