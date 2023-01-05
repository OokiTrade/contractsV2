from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
# deployer = accounts[2]

description = "OOIP-16-update-WBTC-pricefeed"

targets = []
values = []
calldatas = []

WBTCOracle = "0x865d418Bf3a0bf88900c242Aeb3C6dFcFc7b9d34"


calldata = PRICE_FEED.setPriceFeed.encode_input([WBTC], [WBTCOracle])
targets.append(PRICE_FEED)
calldatas.append(calldata)


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
