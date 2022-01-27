exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "REBRAND to OOKI"


GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"




targets = []
values = []
calldatas = []

# TODO rework

# 1. Activate new Staking
gas_price = Wei("80 gwei")
votedelegatorImpl = deployer.deploy(VoteDelegator, gas_price=gas_price) #0x3f8ea74c1f9e2f1d8ce53559491a668c60d4bf04
votedelegatorProxy = deployer.deploy(Proxy_0_5, votedelegatorImpl, gas_price=gas_price) # tx 0x3c25ebf8971c1e2472d1b1ca3d665407a3ea43989bcf95298b68d3cad53894ea addy 0xea936212fe4f3a69d0e8ecf9a2a35d6c1f8d2c89
 
#Contract.from_abi("proxy", "0xea936212fe4f3a69d0e8ecf9a2a35d6c1f8d2c89", Proxy_0_5.abi)
# votedelegatorProxy.replaceImplementation(votedelegatorImpl, {'from': deployer})

stakingModularProxy = deployer.deploy(StakingModularProxy, gas_price=gas_price) # tx 0x4aa33113efd34eb3f2f2b32566e2e8966f886b84346bc3b8027c80a7ce0f89a9 addy 0x16f179f5c344cc29672a58ea327a26f64b941a63

adminSettingsImpl = deployer.deploy(AdminSettings, gas_price=gas_price) # tx 0x63c95a25bd0379494f2bf151e55916ffdbcb0c30ffa0d59f2f6032501ee9d6df nonce 99 addy 0xcc6dc36785d8ec78f401a1d6b6cab560f6dfb92e
rewardsImpl = deployer.deploy(Rewards, gas_price=gas_price, nonce=100) # tx 0xba855dfa0bffd43ca602d0c72dbfdd428bc34a3a5639ba7dffc5d42d92e73739 nonce 100 addy 0x6ebb8f65956d757650ddd1492f1c0f7ffd146f02
stakeUnstakeImpl = deployer.deploy(StakeUnstake, gas_price=gas_price, nonce=101) # tx 0x847293fa5774979be69e8bc5add3e6873df7b62f60c247111cc90ea694f4f59e nonce 101 addy 0x302def543f652068129bbad25615e3231d1ba980
stakingPausableGuardianImpl = deployer.deploy(StakingPausableGuardian, gas_price=gas_price, nonce=102) # tx 0x8f50ac3f1c27cc2a2e47900c2d7f3920ae45ee132e17a2e10fdd93817bac556b nonce 102 addy 0x8262537328b52fb94fa4a53b3daa4180a26d7d06
votingImpl = deployer.deploy(Voting, gas_price=gas_price, nonce=103) # tx 0xcff8c7cf9dbc0b9d09010fd36764d1be4ba561d0b522ce83aa09b0c9a76afd49 nonce 103 addy 0x26c1e80bbd9f44f72d7148124dc8c2f31447d139

stakingModularProxy = Contract.from_abi("StakingModularProxy", "0x16f179f5c344cc29672a58ea327a26f64b941a63", StakingModularProxy.abi)
adminSettingsImpl = Contract.from_abi("AdminSettings", "0xcc6dc36785d8ec78f401a1d6b6cab560f6dfb92e", AdminSettings.abi)
rewardsImpl = Contract.from_abi("Rewards", "0x6ebb8f65956d757650ddd1492f1c0f7ffd146f02", Rewards.abi)
stakeUnstakeImpl = Contract.from_abi("StakeUnstake", "0x302def543f652068129bbad25615e3231d1ba980", StakeUnstake.abi)
stakingPausableGuardianImpl = Contract.from_abi("StakingPausableGuardian", "0x8262537328b52fb94fa4a53b3daa4180a26d7d06", StakingPausableGuardian.abi)
votingImpl = Contract.from_abi("Voting", "0x26c1e80bbd9f44f72d7148124dc8c2f31447d139", Voting.abi)
staking = Contract.from_abi("STAKING", "0x16f179f5c344cc29672a58ea327a26f64b941a63", interface.IStakingV2.abi)
STAKING_VOTE_DELEGATOR = Contract.from_abi("STAKING_VOTE_DELEGATOR", "0xea936212fe4f3a69d0e8ecf9a2a35d6c1f8d2c89", VoteDelegator.abi)

stakingModularProxy.replaceContract(adminSettingsImpl, {"from": deployer, "gas_price": gas_price}) # tx 0x61135fea4298586302e83212bb52f155aa366d12f9853e62c3892997c4ed745b nonce 104
stakingModularProxy.replaceContract(rewardsImpl, {"from": deployer, "gas_price": gas_price, "nonce": 105}) # tx 0x18e3cf45423d70e9a03771da25eb7711b2991a6566fa683094914647924fb8a6
stakingModularProxy.replaceContract(stakeUnstakeImpl, {"from": deployer, "gas_price": gas_price, "nonce": 106}) # tx 0xd72fb1ab141b3aad9e61a0c9a7c3730f566c815afaaea0063d160e7e152c639e
stakingModularProxy.replaceContract(stakingPausableGuardianImpl, {"from": deployer, "gas_price": gas_price, "nonce": 107}) # tx 0xe86131ac9316d1e2d68b3eb6928f1ea9840558e5b6978e4f3ecf7fa23e9f8175
stakingModularProxy.replaceContract(votingImpl, {"from": deployer, "gas_price": gas_price, "nonce": 108}) # tx 0x69df798c13cb0ab96a1cbf76986b449f9931cdb85373871fa73c40766928da3b

staking = Contract.from_abi("STAKING", stakingModularProxy, interface.IStakingV2.abi)
staking.setApprovals(OOKI_ETH_LP, SUSHI_CHEF, 2**256-1, {"from": deployer, "gas_price": gas_price, "nonce": 109}) # tx 0x769b95b4a4f99748b793be8335db380545a20724156572027d2288ad6d432d0b

staking.setApprovals(OOKI_ETH_LP, "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", 0, {"from": deployer, "gas_price": gas_price, "nonce": 119}) # tx 0x7138c516cb6df6a69fd87859e9d04bf193b641b7f65b6ea2a7b4f03fe2c7acb8

staking.setApprovals(OOKI_ETH_LP, SUSHI_CHEF, 2**256-1, {"from": deployer, "gas_price": gas_price, "nonce": 120}) # tx 0x7e20c936520839ba1527da4cf083f5f4de8fbe53fb47abf35f9a97a41b46a749

staking.setApprovals(BZRX, BZRX_TO_OOKI_CONVERTER, 2**256-1, {"from": deployer, "gas_price": gas_price, "nonce": 110}) # tx 0x8a29792265adcbbe367c9423c9cfab78ce315f1c307ea098905eb672cd76b447 

STAKING_VOTE_DELEGATOR.setStaking(staking, {"from": deployer, "gas_price": gas_price}) # tx 0xe501055a56d72c3a1c1ce3dac6332d1a36256b461f71bd1f4832bb3a144d858b
STAKING_VOTE_DELEGATOR.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer,"gas_price": Wei("80 gwei"), "nonce": 121}) # tx 0xdd27a8e8f99dbdb60d1af771a15e55a44137b9097c38f6adca24fad1ded548b9 tx2 0x75ab47cfc4b101690b9bb11c85773aa3b1d68a90c990a87896b9d3ec87e229d9 
staking.setVoteDelegator(STAKING_VOTE_DELEGATOR, {"from": deployer, "gas_price": gas_price, "nonce": 113}) # tx 0x660696e90cf796e25861a8d219260e17aa4dd652dd665c7d430b13babc4e3487

staking.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer, "gas_price": gas_price, "nonce": 122}) # tx 0x6f0324573970832fd41b2c6fb45135066e3cd978ebbcae68396d0da2d454237c tx2 0xeb917408754123d13cf0a9906dfdab93f1aa19f2010aabbc3d4bad96089b7a0e

# upgrade DAO implementation
daoImpl = deployer.deploy(GovernorBravoDelegate, gas_price=Wei("60 gwei"), nonce=115) # tx 0xae3207bda895cdbe17e1d2d15455275c00e4939a22fb34a9378a86a6aa8cdf87
daoImpl = Contract.from_abi("daoImpl", "0xcc4128769826de0489f07869963b757e901f2453", GovernorBravoDelegate.abi)
# below has to be guardian so that it will be by default set
# GUARDIAN_MULTISIG = accounts.at(GUARDIAN_MULTISIG, True)
daoProxy = deployer.deploy(GovernorBravoDelegator, TIMELOCK, staking, TIMELOCK, daoImpl, DAO.votingPeriod(), DAO.votingDelay(), 0.9e18, 3e18, gas_price=Wei("80 gwei"), nonce=116) # tx 0x268c593525b5e241e3639d915677279de48d50bc1d97d1ded12128095163d475 addy 0x3133b4f4dcffc083724435784fefad510fa659c6
daoProxy = Contract.from_abi("daoProxy", "0x3133b4f4dcffc083724435784fefad510fa659c6", GovernorBravoDelegator.abi)

daoProxy.__changeGuardian(GUARDIAN_MULTISIG, {"from": deployer, "gas_price": gas_price, "nonce": 117}) # tx 0xa248ce293660c51f4b1c7c772b34a4789bdebb533b9a8f23ce3869d44555a3b1

staking.setGovernor(daoProxy, {"from": deployer, "gas_price": gas_price, "nonce": 118}) # tx 0x26c49909855cbf72f997a891369f61e8be1f35ab3f31e1bb3cf7abd4e64ce4cc


staking.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer, "gas_price": gas_price}) # tx 0xf1aaf818a9f1f6ee9bcafc4f0f33e77771c2808df3617a3cd52e2017ac115d13
STAKING_VOTE_DELEGATOR.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer, "gas_price": gas_price, "nonce": 124}) # tx 0x8939e0d08c3e70f178d7ed1e6e253e7d01c3a6771cb4ff550ad0c05caa17aa46

eta = TIMELOCK.delay()+ chain.time()+60*60 # 1h delay

DAO_OLD.__queueSetTimelockPendingAdmin(daoProxy, eta, {"from": GUARDIAN_MULTISIG})
# --------------------- TESTING BELOW
chain.sleep(TIMELOCK.delay() + 100)
chain.mine()

DAO_OLD.__executeSetTimelockPendingAdmin(daoProxy, eta, {"from": GUARDIAN_MULTISIG})
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

