exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-9"




targets = []
values = []
calldatas = []

# TODO WIP


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1, "gas_price": gas_price})
