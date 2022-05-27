from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
# deployer = accounts[2]

description = "OOIP-12-celer-bridge-allocation"

targets = []
values = []
calldatas = []

OOKI_AMOUNT = 15000000e18 # 15m ooki
calldata = OOKI.transfer.encode_input(INFRASTRUCTURE_MULTISIG, OOKI_AMOUNT)
targets.append(OOKI)
calldatas.append(calldata)

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
