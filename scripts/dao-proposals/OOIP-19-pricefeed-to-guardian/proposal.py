from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-19-transfer-pricefeed-to-guardian"

NULL = "0x0000000000000000000000000000000000000000"

targets = []
values = []
calldatas = []

targets.append(PRICE_FEED.address)
calldatas.append(PRICE_FEED.transferOwnership.encode_input(GUARDIAN_MULTISIG))
values = [0] * len(targets)  # empty array

signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)