from brownie import *
import pytest
from eth_abi import encode_abi
@pytest.fixture(scope="module")
def DAO(GovernorBravoDelegate):
    return Contract.from_abi("governorBravoDelegator", address="0x3133b4f4dcffc083724435784fefad510fa659c6", abi=GovernorBravoDelegate.abi)

@pytest.fixture(scope="module")
def iWETH(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iWETH", address="0xB983E01458529665007fF7E0CDdeCDB74B967Eb6", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def WSTETH(accounts, TestToken):
    return Contract.from_abi("WSTETH","0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0",TestToken.abi)

@pytest.fixture(scope="module")
def BZX(interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)

def testGovernanceProposal(accounts, DAO, WSTETH, iWETH, BZX, iUSDC):
    wstETH_FEED = PriceFeedwstETH.deploy({"from":accounts[0]}) #Contract.from_abi("","",PriceFeedwstETH.abi)
    wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
    PRICE_FEED = PriceFeeds.at("0x09Ef93750C5F33ab469851F022C1C42056a8BAda")

    PRICE_FEED.setPriceFeed([wstETH],[wstETH_FEED.address], {"from":PRICE_FEED.owner()})

    wstETH_swap = SwapsImplstETH_ETH.deploy({"from":accounts[0]})

    Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).setDexID(wstETH_swap.address, {"from":Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).owner()})

    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    # DAO.execute(10, {"from": proposerAddress})
    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"

    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    voter3 = "0xE9d5472Cc0107938bBcaa630c2e4797F75A2D382"
    voter4 = "0xb37dab352185c1945cc4b7d19ce05602b9db76f8"
        
    exec(open("./scripts/dao-proposals/OOIP-18-wstETH/proposal.py").read())

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
    tx = DAO.castVote(id, 1, {"from": voter3})
    tx = DAO.castVote(id, 1, {"from": voter4})

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

    #source wstETH to open a borrow and open a margin trade for wstETH/ETH and close it
    WSTETH.transfer(accounts[1],1e18, {"from":"0x6ce0f913f035ec6195bc3ce885aec4c66e485bc4"})
    WSTETH.approve(iUSDC.address, 1e18, {"from":accounts[1]})
    iUSDC.borrow(0, 10e6, 0, 1e18, WSTETH, accounts[1], accounts[1], b"", {'from': accounts[1]})
    dex_payload = encode_abi(['uint256'],[int(10e18)])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10
    iWETH.marginTrade(0,9e18,1e18,0,WSTETH.address,accounts[0],loanDataBytes, {"from":accounts[0],"value":1e18})
    loanToAnalyze = BZX.getUserLoans(accounts[0],0,10,0,False,False)[0]
    print(loanToAnalyze)
    dex_payload = encode_abi(['uint256'],[loanToAnalyze[4]])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes1 = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10    
    print(BZX.closeWithSwap(loanToAnalyze[0], accounts[0], loanToAnalyze[5], False, loanDataBytes1, {'from':accounts[0]}).return_value)
    assert False