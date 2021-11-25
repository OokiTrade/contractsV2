exec(open("./scripts/env/set-eth.py").read())
import math

# def main():

acct = accounts.at("0x4c323ea8cd7b3287060cd42def3266a76881a6ac", True)

description = "Compensate users BZRX lost due to hack"


GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
TEAM_WALLET = "0x489F1af9579c63E06E20948EB68A526EAf51BF83"
TEAM_WALLET_AMOUNT = 32101738 * 10**18
COMPENSATION_AMOUNT = 30000000 * 10**18 # 4930m

targets = []
values = []
calldatas = []

# Transfer 25m BZRX to guardian
calldata = BZRX.transfer.encode_input(GUARDIAN_MULTISIG, COMPENSATION_AMOUNT)
targets.append(BZRX)
calldatas.append(calldata)

# Transfer 32m vBZRX to guardian
calldata = vBZRX.transfer.encode_input(TEAM_WALLET, TEAM_WALLET_AMOUNT)
targets.append(vBZRX)
calldatas.append(calldata)





values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': acct, "required_confs": 1})

