exec(open("./scripts/env/set-eth.py").read())

exec(open("./scripts/dao-proposals/OOIP-22-setstethpricefeed/proposal.py").read())
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
wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
assert PRICE_FEED.pricesFeeds(wstETH) == "0x64b068a655985B3AF49814fBe65A3b293B3b811C"
