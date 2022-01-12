#!/usr/bin/python3

import pytest
import time
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


@pytest.fixture(scope="module")
def BZX(interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi)


@pytest.fixture(scope="module")
def VOTE_DELEGATOR(VoteDelegator, Proxy_0_5, accounts):
    votedelegatorProxy = Contract.from_abi(
        "proxy", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", Proxy_0_5.abi)
    votedelegatorImpl = VoteDelegator.deploy({'from': accounts[0]})
    votedelegatorProxy.replaceImplementation(
        votedelegatorImpl, {'from': votedelegatorProxy.owner()})
    return Contract.from_abi("VOTE_DELEGATOR", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", VoteDelegator.abi)


@pytest.fixture(scope="module")
def iBZRX(LoanTokenLogicStandard):
    return Contract.from_abi("iBZRX", "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    return Contract.from_abi("staking", address=stakingAddress, abi=StakingV1_1.abi)


@pytest.fixture(scope="module")
def DAO(GovernorBravoDelegate):
    return Contract.from_abi("DAO", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)


@pytest.fixture(scope="module", autouse=True)
def STAKINGv2(accounts, StakingModularProxy, AdminSettings, StakeUnstake, StakingPausableGuardian, Voting, Rewards, interface, SUSHI_CHEF, OOKI_ETH_LP, BZRX, BZRXv2_CONVERTER, CRV3, POOL3_GAUGE, VOTE_DELEGATOR, DAO):
    stakingModularProxy = accounts[0].deploy(StakingModularProxy)

    adminSettingsImpl = accounts[0].deploy(AdminSettings)
    rewardsImpl = accounts[0].deploy(Rewards)
    stakeUnstakeImpl = accounts[0].deploy(StakeUnstake)
    stakingPausableGuardianImpl = accounts[0].deploy(StakingPausableGuardian)
    votingImpl = accounts[0].deploy(Voting)

    stakingModularProxy.replaceContract(adminSettingsImpl)
    stakingModularProxy.replaceContract(rewardsImpl)
    stakingModularProxy.replaceContract(stakeUnstakeImpl)
    stakingModularProxy.replaceContract(stakingPausableGuardianImpl)
    stakingModularProxy.replaceContract(votingImpl)

    # setting approvals
    staking = Contract.from_abi(
        "STAKING", stakingModularProxy, interface.IStakingV2.abi)
    staking.setApprovals(OOKI_ETH_LP, SUSHI_CHEF, 2 **
                         256-1, {"from": staking.owner()})
    staking.setApprovals(BZRX, BZRXv2_CONVERTER, 2**256 -
                         1, {"from": staking.owner()})
    staking.setApprovals(CRV3, POOL3_GAUGE, 1, {"from": staking.owner()})

    # reference vote delegator and staking to each other
    VOTE_DELEGATOR.setStaking(staking, {"from": VOTE_DELEGATOR.owner()})
    staking.setVoteDelegator(VOTE_DELEGATOR, {"from": staking.owner()})
    staking.setGovernor(DAO, {"from": staking.owner()})

    return staking


@pytest.fixture(scope="module")
def BZRXv2_CONVERTER(BZRXv2Converter, MINT_COORDINATOR):
    # set mint coordinator
    converter = Contract.from_abi(
        "BZRXv2_CONVERTER", address="0x6BE9B7406260B6B6db79a1D4997e7f8f5c9D7400", abi=BZRXv2Converter.abi)
    # converter.initialize(MINT_COORDINATOR, {"from": converter.owner()})
    MINT_COORDINATOR.addMinter(converter, {"from": MINT_COORDINATOR.owner()})
    return converter


@pytest.fixture(scope="module")
def MINT_COORDINATOR(MintCoordinator):
    return Contract.from_abi("MINT_COORDINATOR", "0x93c608Dc45FcDd9e7c5457ce6fc7f4dDec235b68", abi=MintCoordinator.abi)


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass


@pytest.fixture(scope="module")
def CRV(TestToken):
    return Contract.from_abi("CRV", "0xD533a949740bb3306d119CC777fa900bA034cd52", TestToken.abi)


@pytest.fixture(scope="module")
def vBZRX(BZRXVestingToken):
    return Contract.from_abi("vBZRX", "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", BZRXVestingToken.abi)


@pytest.fixture(scope="module")
def SUSHI_CHEF(interface):
    chef = Contract.from_abi(
        "CHEF", "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd", interface.IMasterChefSushi.abi)
    return chef


@pytest.fixture(scope="module")
def BZRX(TestToken):
    return Contract.from_abi("BZRX", "0x56d811088235F11C8920698a204A5010a788f4b3", TestToken.abi)


@pytest.fixture(scope="module")
def CRV3(TestToken):
    return Contract.from_abi("CRV3", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)


@pytest.fixture(scope="module")
def POOL3_GAUGE(interface):
    return Contract.from_abi("POOL3", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi)


@pytest.fixture(scope="module")
def iOOKI(LoanTokenLogicStandard):
    return Contract.from_abi("iOOKI", "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def OOKI(TestToken):
    return Contract.from_abi("OOKI", "0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", TestToken.abi)


@pytest.fixture(scope="module")
def SUSHI(TestToken):
    return Contract.from_abi("SUSHI", "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2", TestToken.abi)


@pytest.fixture(scope="module")
def SUSHI_ROUTER(TestToken, interface):
    return Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)


@pytest.fixture(scope="module")
def OOKI_ETH_LP(TestToken, interface):
    return Contract.from_abi("OOKI_ETH_LP", "0xEaaddE1E14C587a7Fb4Ba78eA78109BB32975f1e", interface.IPancakePair.abi)
