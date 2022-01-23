exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *

# def main():

deployer = accounts.at("0x4c323ea8cd7b3287060cd42def3266a76881a6ac", True)

description = "REBRAND to OOKI"


GUARDIAN_MULTISIG = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"




targets = []
values = []
calldatas = []

# TODO rework

# 1. Activate new Staking
votedelegatorProxy = Contract.from_abi("proxy", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", Proxy_0_5.abi)
votedelegatorImpl = VoteDelegator.deploy({'from': deployer})
votedelegatorProxy.replaceImplementation(votedelegatorImpl, {'from': votedelegatorProxy.owner()})

stakingModularProxy = deployer.deploy(StakingModularProxy)

adminSettingsImpl = deployer.deploy(AdminSettings)
rewardsImpl = deployer.deploy(Rewards)
stakeUnstakeImpl = deployer.deploy(StakeUnstake)
stakingPausableGuardianImpl = deployer.deploy(StakingPausableGuardian)
votingImpl = deployer.deploy(Voting)

stakingModularProxy.replaceContract(adminSettingsImpl)
stakingModularProxy.replaceContract(rewardsImpl)
stakingModularProxy.replaceContract(stakeUnstakeImpl)
stakingModularProxy.replaceContract(stakingPausableGuardianImpl)
stakingModularProxy.replaceContract(votingImpl)
staking = Contract.from_abi("STAKING", stakingModularProxy, interface.IStakingV2.abi)
staking.setApprovals(OOKI_ETH_LP, SUSHI_CHEF, 2**256-1, {"from": deployer})
staking.setApprovals(BZRX, BZRX_TO_OOKI_CONVERTER, 2**256-1, {"from": deployer})
staking.setApprovals(CRV3, POOL3_GAUGE, 1, {"from": deployer})

STAKING_VOTE_DELEGATOR = Contract.from_abi("STAKING_VOTE_DELEGATOR", votedelegatorProxy, VoteDelegator.abi)
STAKING_VOTE_DELEGATOR.setStaking(staking, {"from": STAKING_VOTE_DELEGATOR.owner()}) # T is the owner
staking.setVoteDelegator(STAKING_VOTE_DELEGATOR, {"from": deployer})


# upgrade DAO implementation
daoImpl = deployer.deploy(GovernorBravoDelegate)
# below has to be guardian so that it will be by default set
GUARDIAN_MULTISIG = accounts.at(GUARDIAN_MULTISIG, True)
daoProxy = GUARDIAN_MULTISIG.deploy(GovernorBravoDelegator, TIMELOCK, staking, TIMELOCK, daoImpl, DAO.votingPeriod(), DAO.votingDelay(), 1.4e18, 3e18)


staking.setGovernor(daoProxy, {"from": deployer})
staking.transferOwnership(TIMELOCK, {"from": deployer})

eta = TIMELOCK.delay()+ chain.time()+100

DAO.__queueSetTimelockPendingAdmin(daoProxy, eta, {"from": GUARDIAN_MULTISIG})
chain.sleep(TIMELOCK.delay() + 100)
chain.mine()
DAO.__executeSetTimelockPendingAdmin(daoProxy, eta, {"from": GUARDIAN_MULTISIG})
print("pending admin set")



DAO = Contract.from_abi("governorBravoDelegator", address=daoProxy, abi=GovernorBravoDelegate.abi)
DAO.__acceptAdmin({"from": GUARDIAN_MULTISIG})

assert DAO.staking() == staking
assert DAO.admin() == TIMELOCK
assert TIMELOCK.admin() == DAO
# values = [0] * len(targets)  # empty array
# signatures = [""] * len(targets)  # empty signatures array


# # Make proposal
# DAO.propose(targets, values, signatures, calldatas, description, {'from': deployer, "required_confs": 1})

