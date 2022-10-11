from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
# deployer = accounts[2]

description = "OOIP-15-minimal-interest-rate/Lawyer-Fund-Allocation"

targets = []
values = []
calldatas = []

#1 minimal interest rate
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for assetPair in supportedTokenAssetsPairs:
    if assetPair[0] != "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da": # multisig owns iooki. will be updates separately
        existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
        calldata = existingIToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(CUI))

        targets.append(existingIToken)
        calldatas.append(calldata)

#2 allocate funds
BZRX_AMOUNT = 3110000e18
calldata = BZRX.transfer.encode_input(INFRASTRUCTURE_MULTISIG, BZRX_AMOUNT)
targets.append(BZRX)
calldatas.append(calldata)


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
