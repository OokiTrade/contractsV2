from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-9 sweep fees"

targets = []
values = []
calldatas = []

# accounts.load()

# 1. redeploy old staking
stakingProxy = Contract.from_abi("proxy", STAKING_OLD, StakingProxy.abi)
calldata = stakingProxy.replaceImplementation.encode_input("0x4F04409A3596FC04af39EfE29222E4f2657433cA")
targets.append(STAKING_OLD)
calldatas.append(calldata)


# 2. switch fee controller
calldata = BZX.setFeesController.encode_input('0xfFB328AD3b727830F9482845A4737AfDDDe85554')

targets.append(BZX)
calldatas.append(calldata)


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
TEAM_VOTING_MULTISIG = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {"from": TEAM_VOTING_MULTISIG})
print("call", call)
