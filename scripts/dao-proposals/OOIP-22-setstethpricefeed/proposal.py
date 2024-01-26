from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-22"

wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
NULL = "0x0000000000000000000000000000000000000000"

targets = []
values = []
calldatas = []

wstETH_FEED = PriceFeedwstETH.at("0x64b068a655985B3AF49814fBe65A3b293B3b811C")
wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"

targets.append(PRICE_FEED.address)
calldatas.append(PRICE_FEED.setPriceFeed.encode_input([wstETH],[wstETH_FEED.address]))

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': ""})
print("call", call)