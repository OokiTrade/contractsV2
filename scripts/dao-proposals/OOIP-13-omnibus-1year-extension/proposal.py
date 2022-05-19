from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
# deployer = accounts[2]

description = "OOIP-13-omnibus-1year-extension"

targets = []
values = []
calldatas = []

BZRX_AMOUNT = 20400000e18 # 204m ooki, 1 year allowance
calldata = BZRX.approve.encode_input(DAO_FUNDING, BZRX_AMOUNT)
targets.append(BZRX)
calldatas.append(calldata)

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
