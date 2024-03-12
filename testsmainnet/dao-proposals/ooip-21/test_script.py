exec(open("./scripts/env/set-eth.py").read())

beforeTokenPrice = iUSDC.tokenPrice()
beforeTotalAssetBorrow = iUSDC.totalAssetBorrow()
beforeTotalAssetSupply = iUSDC.totalAssetSupply()
beforeTotalSupply = iUSDC.totalSupply()
print("beforeTokenPrice", beforeTokenPrice)
print("beforeTotalAssetBorrow", beforeTotalAssetBorrow)
print("beforeTotalAssetSupply", beforeTotalAssetSupply)
print("beforeTotalSupply", beforeTotalSupply)

exec(open("./scripts/dao-proposals/OOIP-21-pricefeed-update/before_proposal.py").read())
exec(open("./scripts/dao-proposals/OOIP-21-pricefeed-update/proposal.py").read())
voter1 = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
voter2 = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
voter3 = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"
proposerAddress = "0xE9d5472Cc0107938bBcaa630c2e4797F75A2D382"

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
DAO.execute(id, {"from": accounts[2]})


afterTokenPrice = iUSDC.tokenPrice()
afterTotalAssetBorrow = iUSDC.totalAssetBorrow()
afterTotalAssetSupply = iUSDC.totalAssetSupply()
afterTotalSupply = iUSDC.totalSupply()

print("afterTokenPrice", afterTokenPrice)
print("afterTotalAssetBorrow", afterTotalAssetBorrow)
print("afterTotalAssetSupply", afterTotalAssetSupply)
print("afterTotalSupply", afterTotalSupply)



BZX.toggleFunctionUnPause(BZX.borrowOrTradeFromPool.signature, {'from': GUARDIAN_MULTISIG})

iUSDC.borrow(0, 1e6, 90999999999, 90e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {"from": accounts[0], "value": Wei("90 ether")})

beforeTokenPrice = iUSDC.tokenPrice()
iUSDC.borrow(0, 1e6, 90999999999, 90e18, ZERO_ADDRESS, accounts[1], accounts[1], b'', {"from": accounts[1], "value": Wei("90 ether")})
afterTokenPrice = iUSDC.tokenPrice()
assert beforeTokenPrice <= afterTokenPrice

chain.mine(blocks=100)
holderUSDC = "0xcEe284F754E854890e311e3280b767F80797180d"
USDC.transfer(accounts[0], 200000e6, {"from": holderUSDC})
USDC.approve(BZX, 2**256-1, {"from": accounts[0]})

loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
loanId = loans[0][0]
BZX.closeWithDeposit(loanId, accounts[0], 200000e6, b'', {"from": accounts[0]})

beforeTokenPrice = iUSDC.tokenPrice()
iUSDC.marginTrade(0, 2e18, 0, 0.01*1e18, WETH, accounts[0], b'',{'from': accounts[0], "value": Wei("0.01 ether")})
afterTokenPrice = iUSDC.tokenPrice()
assert beforeTokenPrice <= afterTokenPrice

tokenPrice1 = iUSDC.tokenPrice()/1e18
USDC.transfer(iUSDC, 2000000* 10**6, {'from': "0x5B541d54e79052B34188db9A43F7b00ea8E2C4B1"})
tokenPrice2 = iUSDC.tokenPrice()/1e18
assert tokenPrice2 < tokenPrice1 * 1.0001
iUSDC.consume(2000000* 10**6, {'from' : GUARDIAN_MULTISIG})
tokenPrice3 =iUSDC.tokenPrice()/1e18
assert tokenPrice3 > 2 * tokenPrice1
assert DAO.quorumPercentage() == DAO.MIN_QUORUM_PERCENTAGE()
assert False