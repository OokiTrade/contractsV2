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


#Execute OOIP-11
proposalCount = DAO.proposalCount()
proposal = DAO.proposals(proposalCount)
id = proposal[0]
startBlock = proposal[3]
endBlock = proposal[4]
assert DAO.state.call(id) == 0
print("Mine", startBlock - chain.height + 1, "blocks")
chain.mine(startBlock - chain.height + 1)
assert DAO.state.call(id) == 1
tx = DAO.castVote(id, 1, {"from": proposerAddress})
tx = DAO.castVote(id, 1, {"from": voter1})
tx = DAO.castVote(id, 1, {"from": voter2})
assert DAO.state.call(id) == 1
print("Mine", endBlock - chain.height, "blocks")
chain.mine(endBlock - chain.height)
assert DAO.state.call(id) == 1
chain.mine()
assert DAO.state.call(id) == 4
print("queue proposal")
DAO.queue(id, {"from": proposerAddress})
proposal = DAO.proposals(proposalCount)
eta = proposal[2]
chain.sleep(eta - chain.time())
chain.mine()
print("execute proposal")
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
        migrator.migrateLoans(iToken,count * x, count, {'from': GUARDIAN_MULTISIG})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    if(existingIToken == iOOKI):
        continue
    print("Migrate: ", existingIToken.symbol())
    migrate(existingIToken, migrator)

protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
    BZX.liquidate.signature,
    BZX.depositCollateral.signature,
    BZX.withdrawCollateral.signature,
    BZX.settleInterest.signature
]
print("unpause protocol")
BZX.unpause(protocolPauseSignatures, {'from': GUARDIAN_MULTISIG})

LINK.transfer(accounts[1], 2000e18, {'from': "0x0d4f1ff895d12c34994d6b65fabbeefdc1a9fb39"})
USDC.transfer(accounts[1], 10000e6, {'from': '0xdf0770df86a8034b3efef0a1bb3c889b8332ff56'})
WBTC.transfer(accounts[1], 0.02e8, {'from': "0xb60c61dbb7456f024f9338c739b02be68e3f545c"})
WETH.transfer(accounts[1], 2e18, {'from': "0xf04a5cc80b1e94c69b48f5ee68a08cd2f09a7c3e"})
APE.transfer(accounts[1], 30000e18, {'from': '0x91951fa186a77788197975ed58980221872a3352'})
USDT.transfer(accounts[1], 200e6, {'from': "0x61f2f664fec20a2fc1d55409cfc85e1baeb943e2"})


# BORROW, MINT, TRADE
print("Borrow USDC, collateral ETH")
USDC.approve(iUSDC, 2**256-1, {'from': accounts[1]})
iUSDC.mint(accounts[1], 1000e6, {'from': accounts[1]})
iUSDC.borrow("", 50e6, 7884000, 1e18, '0x0000000000000000000000000000000000000000', accounts[1], accounts[1], b"", {'from': accounts[1], 'value':1e18})

print("Borrow USDC, collateral WBTC")
WBTC.approve(iUSDC, 2**256-1, {'from':accounts[1]})
iUSDC.borrow("", 10e6, 7884000, 0.005e8, WBTC, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow USDC, collateral WETH")
WETH.approve(iUSDC, 2**256-1, {'from':accounts[1]})
iUSDC.borrow("", 150e6, 7884000, 1e18, WETH, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow USDC, collateral LINK")
LINK.approve(iUSDC, 2**256-1, {'from':accounts[1]})
iUSDC.borrow("", 10e6, 7884000, 10e18, LINK, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow LINK, collateral USDC")
USDC.approve(iLINK, 2**256-1, {'from':accounts[1]})
iLINK.borrow("", 1e18, 7884000, 20e6, USDC, accounts[1], accounts[1], b"", {'from': accounts[1]})

trades = BZX.getUserLoans(accounts[1], 0,10, 0,0,0)
interface.IERC20(trades[0][2]).approve(BZX, 2**256-1, {'from': accounts[1]})
BZX.closeWithDeposit(trades[0][0],accounts[1],trades[0][4],{'from':accounts[1]})

print("Trade USDC/ETH")
iUSDC.marginTrade(0, 2e18, 0, 0.04e18, "0x0000000000000000000000000000000000000000", accounts[1], b'',{'from': accounts[1],  'value': Wei(0.04e18)})
print("Trade USDC/WETH")
iUSDC.marginTrade(0, 2e18, 0, 0.04e18, WETH, accounts[1], b'',{'from': accounts[1],  'value': Wei(0.04e18)})
print("Trade USDC/LINK")
iUSDC.marginTrade(0, 2e18, 0, 1e18, LINK, accounts[1], b'',{'from': accounts[1]})
print("Trade USDC/WBTC")
iUSDC.marginTrade(0, 2e18, 0, 0.005e8, WBTC, accounts[1], b'',{'from': accounts[1]})
print("Trade WBTC/USDC")
USDC.approve(iWBTC, 2**256-1, {'from':accounts[1]})
iWBTC.marginTrade(0, 2e18, 0, 100e6, USDC, accounts[1], b'',{'from': accounts[1]})
print("Trade WBTC/LINK")
LINK.approve(iWBTC, 2**256-1, {'from':accounts[1]})
iWBTC.marginTrade(0, 2e18, 0, 10e18, LINK, accounts[1], b'',{'from': accounts[1]})
print("Trade ETH/LINK")
LINK.approve(iETH, 2**256-1, {'from':accounts[1]})
iETH.marginTrade(0, 2e18, 0, 10e18, LINK, accounts[1], b'',{'from': accounts[1]})


print("Borrow APE, collateral ETH")

APE.approve(iAPE, 2**256-1, {'from': accounts[1]})
iAPE.mint(accounts[1], 2000e18, {'from': accounts[1]})
iAPE.borrow("", 50e18, 7884000, 1e18, '0x0000000000000000000000000000000000000000', accounts[1], accounts[1], b"", {'from': accounts[1], 'value':1e18})

print("Borrow APE, collateral USDT")
USDT.approve(iAPE, 2**256-1, {'from':accounts[1]})
iAPE.borrow("", 1e18, 7884000, 100e6, USDT, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow APE, collateral WETH")
WETH.approve(iAPE, 2**256-1, {'from':accounts[1]})
iAPE.borrow("", 1e18, 7884000, 1e18, WETH, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow APE, collateral LINK")
LINK.approve(iAPE, 2**256-1, {'from':accounts[1]})
iAPE.borrow("", 1e18, 7884000, 100e18, LINK, accounts[1], accounts[1], b"", {'from': accounts[1]})

print("Borrow LINK, collateral APE")
APE.approve(iLINK, 2**256-1, {'from':accounts[1]})
iLINK.borrow("", 1e18, 7884000, 10e18, APE, accounts[1], accounts[1], b"", {'from': accounts[1]})

trades = BZX.getUserLoans(accounts[1], 0,10, 0,0,0)
interface.IERC20(trades[0][2]).approve(BZX, 2**256-1, {'from': accounts[1]})
BZX.closeWithDeposit(trades[0][0],accounts[1],trades[0][4],{'from':accounts[1]})

print("Trade APE/ETH")
iAPE.marginTrade(0, 2e18, 0, 0.04e18, "0x0000000000000000000000000000000000000000", accounts[1], b'',{'from': accounts[1],  'value': Wei(0.04e18)})
print("Trade APE/WETH")
iAPE.marginTrade(0, 2e18, 0, 0.04e18, WETH, accounts[1], b'',{'from': accounts[1],  'value': Wei(0.04e18)})
print("Trade APE/LINK")
iAPE.marginTrade(0, 2e18, 0, 1e18, LINK, accounts[1], b'',{'from': accounts[1]})
print("Trade APE/USDT")
iAPE.marginTrade(0, 2e18, 0, 1e6, USDT, accounts[1], b'',{'from': accounts[1]})
print("Trade USDT/APE")
APE.approve(iUSDT, 2**256-1, {'from':accounts[1]})
iUSDT.marginTrade(0, 2e18, 0, 1e18, APE, accounts[1], b'',{'from': accounts[1]})