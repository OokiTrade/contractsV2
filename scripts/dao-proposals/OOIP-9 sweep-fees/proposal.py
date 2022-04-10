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


# Make proposal
call = DAO.propose.encode_input(targets, values, signatures, calldatas, description)
print("call", call)
