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



# 1. Disable Sweep Fees
calldata = BZX.setFeesController.encode_input(ZERO_ADDRESS)
targets.append(BZX)
calldatas.append(calldata)

# 2. Activate new Staking
votedelegatorProxy = Contract.from_abi("proxy", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", Proxy_0_5.abi)
votedelegatorImpl = VoteDelegator.deploy({'from': deployer})
votedelegatorProxy.replaceImplementation(votedelegatorImpl, {'from': votedelegatorProxy.owner()})

stakingModularProxy = deployer.deploy(StakingModularProxy)

adminSettingsImpl = deployer.deploy(AdminSettings)
# rewardsImpl = deployer.deploy(Rewards) TODO need help from T
stakeUnstakeImpl = deployer.deploy(StakeUnstake)
stakingPausableGuardianImpl = deployer.deploy(StakingPausableGuardian)
votingImpl = deployer.deploy(Voting)

stakingModularProxy.replaceContract(adminSettingsImpl)
# stakingModularProxy.replaceContract(rewardsImpl) 
stakingModularProxy.replaceContract(stakeUnstakeImpl)
stakingModularProxy.replaceContract(stakingPausableGuardianImpl)
stakingModularProxy.replaceContract(votingImpl)
staking = Contract.from_abi("STAKING", stakingModularProxy, interface.IStakingV2.abi)
staking.setApprovals(OOKI_ETH_LP, SUSHI_CHEF, 2**256-1, {"from": deployer})
staking.setApprovals(BZRX, BZRX_V2_CONVERTER, 2**256-1, {"from": deployer})
staking.setApprovals(CRV3, POOL3_GAUGE, 1, {"from": deployer})

STAKING_VOTE_DELEGATOR = Contract.from_abi("STAKING_VOTE_DELEGATOR", votedelegatorProxy, VoteDelegator.abi)
STAKING_VOTE_DELEGATOR.setStaking(staking, {"from": STAKING_VOTE_DELEGATOR.owner()}) # T is the owner
staking.setVoteDelegator(STAKING_VOTE_DELEGATOR, {"from": deployer})
staking.transferOwnership(TIMELOCK, {"from": deployer})

# 3. DAO use new staking for voting
# upgrade DAO implementation
daoImpl = "0xb7A0B67fF67B548e91953647F8cDd7647660279d" # acct.deploy(GovernorBravoDelegate)
daoProxy = Contract.from_abi("GovernorBravoDelegator", address=DAO, abi=GovernorBravoDelegator.abi) # attire proxy interface
calldata = daoProxy._setImplementation.encode_input(daoImpl)
targets.append(daoProxy)
calldatas.append(calldata)

calldata = DAO.__setStaking.encode_input(staking)
targets.append(daoProxy)
calldatas.append(calldata)

# 4. BZRXv2_CONVERTER initialize (multisig)
# TODO manual
# 5. MINT_COORDINATOR.addMinter (multisig)
# TODO manual



values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': deployer, "required_confs": 1})

