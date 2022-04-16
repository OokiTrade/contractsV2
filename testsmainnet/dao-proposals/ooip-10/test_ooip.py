#!/usr/bin/python3

import pytest
from brownie import *
import pdb

exec(open("./scripts/dao-proposals/OOIP-10-iAPE/proposal.py").read())
exec(open("./scripts/env/set-eth.py").read())
proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"

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
exec(open("./scripts/env/set-eth.py").read())

print("Borrow APE, collateral ETH")
APE.transfer(accounts[0], 1000e18, {'from': '0xa56cf001966d179751ba1c7fb5d137b4c5f344cc'})
APE.approve(iAPE, 2**256-1, {'from': accounts[0]})
iAPE.mint(accounts[0], 100e18, {'from': accounts[0]})
iAPE.borrow("", 50e18, 7884000, 1e18, '0x0000000000000000000000000000000000000000', accounts[0], accounts[0], b"", {'from': accounts[0], 'value':1e18})

print("Borrow APE, collateral USDT")
USDT.transfer(accounts[0], 200e6, {'from': iUSDT})
USDT.approve(iAPE, 2**256-1, {'from':accounts[0]})
iAPE.borrow("", 1e18, 7884000, 100e6, USDT, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow APE, collateral WETH")
WETH.transfer(accounts[0], 1e18, {'from': iETH})
WETH.approve(iAPE, 2**256-1, {'from':accounts[0]})
iAPE.borrow("", 1e18, 7884000, 1e18, WETH, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow APE, collateral LINK")
LINK.transfer(accounts[0], 200e18, {'from': iLINK})
LINK.approve(iAPE, 2**256-1, {'from':accounts[0]})
iAPE.borrow("", 1e18, 7884000, 100e18, LINK, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow LINK, collateral APE")
APE.approve(iLINK, 2**256-1, {'from':accounts[0]})
iLINK.borrow("", 1e18, 7884000, 10e18, APE, accounts[0], accounts[0], b"", {'from': accounts[0]})

trades = BZX.getUserLoans(accounts[0], 0,10, 0,0,0)
LINK.approve(BZX, 2**256-1, {'from': accounts[0]})
BZX.closeWithDeposit(trades[0][0],accounts[0],trades[0][4],{'from':accounts[0]})

print("Trade APE/ETH")
iAPE.marginTrade(0, 2e18, 0, 0.04e18, "0x0000000000000000000000000000000000000000", accounts[0], b'',{'from': accounts[0],  'value': Wei(0.04e18)})
print("Trade APE/WETH")
iAPE.marginTrade(0, 2e18, 0, 0.04e18, WETH, accounts[0], b'',{'from': accounts[0],  'value': Wei(0.04e18)})
print("Trade APE/LINK")
iAPE.marginTrade(0, 2e18, 0, 100e18, LINK, accounts[0], b'',{'from': accounts[0]})
print("Trade APE/USDT")
iAPE.marginTrade(0, 2e18, 0, 100e6, USDT, accounts[0], b'',{'from': accounts[0]})
print("Trade USDT/APE")
iUSDT.marginTrade(0, 20e6, 0, 100e18, APE, accounts[0], b'',{'from': accounts[0]})