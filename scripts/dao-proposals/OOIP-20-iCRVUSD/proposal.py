from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]
targets = []
calldatas = []
description = "OOIP-20 iUsdCrv"
CRVUSD_TOKEN = '0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E'
PRICE_FEED_ADDRESS = '0xE4Ac87b95FFb28FDCb009009b4eDF949702f1785'
# 1. deploy icrvUSD
loanTokenLogicStandard = "0x624f7f89414011b276c60ea2337bfba936d1cbbe"
iTokenProxy = Contract.from_abi("LoanToken", address="0x3D87106A93F56ceE890769A808Af62Abc67ECBD3", abi=LoanToken.abi)
iToken = Contract.from_abi("existingIToken", address=iTokenProxy, abi=LoanTokenLogicStandard.abi)
loanToken = Contract.from_abi("token", address=CRVUSD_TOKEN, abi=TestToken.abi)

# 2. Add pricefeed to protocol
targets.append(PRICE_FEED.address)
calldatas.append(PRICE_FEED.setPriceFeed.encode_input([CRVUSD_TOKEN], [PRICE_FEED_ADDRESS]))

targets.append(PRICE_FEED.address)
calldatas.append(PRICE_FEED.setDecimals.encode_input([iToken.loanTokenAddress()]))

targets.append(BZX.address)
calldatas.append(BZX.setApprovals.encode_input([iToken.loanTokenAddress()], [1,2]))

targets.append(BZX.address)
calldatas.append(BZX.setupLoanPoolTWAI.encode_input(iToken))

targets.append(BZX.address)
calldatas.append(BZX.setLoanPool.encode_input([iToken], [iToken.loanTokenAddress()]))

targets.append(BZX.address)
calldatas.append(BZX.setSupportedTokens.encode_input([iToken.loanTokenAddress()], [True], True))

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
TEAM_VOTING_MULTISIG = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"

# Make proposal
OOKI.approve(STAKING, 2**256-1, {'from': '0x5a52E96BAcdaBb82fd05763E25335261B270Efcb'})
STAKING.stake([OOKI], [50e25], {'from': '0x5a52E96BAcdaBb82fd05763E25335261B270Efcb'})
call = DAO.propose(targets, values, signatures, calldatas, description, {"from": '0x5a52E96BAcdaBb82fd05763E25335261B270Efcb'})
print("call", call)


print("targets: ", targets)
print("values: ", values)
print("signatures: ", signatures)
print("calldatas: ", calldatas)
print("description: ", description)

#Todo: run from guardian before execution
#CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, 0.8e18, 0.8e18), iToken, {"from": GUARDIAN_MULTISIG})