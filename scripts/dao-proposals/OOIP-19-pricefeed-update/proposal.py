from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-19-pricefeed-update"

targets = []
values = []
calldatas = []

targets.append(PRICE_FEED.address)
calldatas.append( PRICE_FEED.setPriceFeed.encode_input([USDC, USDT], ['0x986b5E1e1755e3C2440e960477f25201B0a8bbD4', '0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46']))
values = [0] * len(targets)  # empty array

signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)