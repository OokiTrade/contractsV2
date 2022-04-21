#!/usr/bin/python3

import pytest
from brownie import *
import pdb
exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/dao-proposals/OOIP-11-loan-migration/before_proposal.py").read())
exec(open("./scripts/dao-proposals/OOIP-11-loan-migration/proposal.py").read())
proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"


# Execute OOIP-10 add iAPE
proposalCount = DAO.proposalCount()-1
proposal = DAO.proposals(proposalCount)
id = proposal[0]
startBlock = proposal[3]
endBlock = proposal[4]
proposal = DAO.proposals(proposalCount)
eta = proposal[2]
chain.sleep(eta - chain.time())
chain.mine()
DAO.execute(id, {"from": proposerAddress})

#Execute OOIP-11
proposalCount = DAO.proposalCount()
proposal = DAO.proposals(proposalCount)
id = proposal[0]
startBlock = proposal[3]
endBlock = proposal[4]
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

# MIGRATE LOANS
USDT.transfer(BZX, 1000e6, {'from': '0x61f2f664fec20a2fc1d55409cfc85e1baeb943e2'})
def migrate(iToken, migrator):
    end = migrator.getLoanCount(iToken)
    count = 10
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        migrator.migrateLoans(iToken,count * x, count, {'from': TIMELOCK})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    if(existingIToken == iOOKI):
        continue

    migrate(existingIToken, migrator)

protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
    BZX.liquidate.signature,
    BZX.depositCollateral.signature,
    BZX.withdrawCollateral.signature,
    BZX.settleInterest.signature
]
BZX.unpause(protocolPauseSignatures, {'from': TIMELOCK})

# BORROW, MINT, TRADE
print("Borrow USDC, collateral ETH")
USDC.transfer(accounts[0], 10000e6, {'from': '0xdf0770df86a8034b3efef0a1bb3c889b8332ff56'})
USDC.approve(iUSDC, 2**256-1, {'from': accounts[0]})
iUSDC.mint(accounts[0], 1000e6, {'from': accounts[0]})
iUSDC.borrow("", 50e6, 7884000, 1e18, '0x0000000000000000000000000000000000000000', accounts[0], accounts[0], b"", {'from': accounts[0], 'value':1e18})

print("Borrow USDC, collateral WBTC")
WBTC.transfer(accounts[0], 0.02e8, {'from': "0xb60c61dbb7456f024f9338c739b02be68e3f545c"})
WBTC.approve(iUSDC, 2**256-1, {'from':accounts[0]})
iUSDC.borrow("", 10e6, 7884000, 0.005e8, WBTC, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow USDC, collateral WETH")
WETH.transfer(accounts[0], 1e18, {'from': "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3"})
WETH.approve(iUSDC, 2**256-1, {'from':accounts[0]})
iUSDC.borrow("", 150e6, 7884000, 1e18, WETH, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow USDC, collateral LINK")
LINK.transfer(accounts[0], 1000e18, {'from': "0x0d4f1ff895d12c34994d6b65fabbeefdc1a9fb39"})
LINK.approve(iUSDC, 2**256-1, {'from':accounts[0]})
iUSDC.borrow("", 10e6, 7884000, 10e18, LINK, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow LINK, collateral USDC")
USDC.approve(iLINK, 2**256-1, {'from':accounts[0]})
iLINK.borrow("", 1e18, 7884000, 20e6, USDC, accounts[0], accounts[0], b"", {'from': accounts[0]})

trades = BZX.getUserLoans(accounts[0], 0,10, 0,0,0)
LINK.approve(BZX, 2**256-1, {'from': accounts[0]})
BZX.closeWithDeposit(trades[0][0],accounts[0],trades[0][4],{'from':accounts[0]})

print("Trade USDC/ETH")
iUSDC.marginTrade(0, 2e18, 0, 0.04e18, "0x0000000000000000000000000000000000000000", accounts[0], b'',{'from': accounts[0],  'value': Wei(0.04e18)})
print("Trade USDC/WETH")
iUSDC.marginTrade(0, 2e18, 0, 0.04e18, WETH, accounts[0], b'',{'from': accounts[0],  'value': Wei(0.04e18)})
print("Trade USDC/LINK")
iUSDC.marginTrade(0, 2e18, 0, 1e18, LINK, accounts[0], b'',{'from': accounts[0]})
print("Trade USDC/WBTC")
iUSDC.marginTrade(0, 2e18, 0, 0.005e8, WBTC, accounts[0], b'',{'from': accounts[0]})
print("Trade WBTC/USDC")
USDC.approve(iWBTC, 2**256-1, {'from':accounts[0]})
iWBTC.marginTrade(0, 2e18, 0, 100e6, USDC, accounts[0], b'',{'from': accounts[0]})
print("Trade WBTC/LINK")
LINK.approve(iWBTC, 2**256-1, {'from':accounts[0]})
iWBTC.marginTrade(0, 2e18, 0, 10e18, LINK, accounts[0], b'',{'from': accounts[0]})
print("Trade ETH/LINK")
LINK.approve(iETH, 2**256-1, {'from':accounts[0]})
iETH.marginTrade(0, 2e18, 0, 10e18, LINK, accounts[0], b'',{'from': accounts[0]})