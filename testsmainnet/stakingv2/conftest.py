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
def VOTE_DELEGATOR(VoteDelegator, Proxy_0_5, accounts, TIMELOCK):
    votedelegatorProxy = Contract.from_abi("proxy", "0xea936212fe4f3a69d0e8ecf9a2a35d6c1f8d2c89", Proxy_0_5.abi)

    # votedelegatorImpl = VoteDelegator.deploy({'from': accounts[0]})
    # votedelegatorProxy.replaceImplementation(
    #     votedelegatorImpl, {'from': votedelegatorProxy.owner()})

    votedelegatorProxy.transferOwnership(TIMELOCK, {"from": votedelegatorProxy.owner()})

    return Contract.from_abi("VOTE_DELEGATOR", "0xea936212fe4f3a69d0e8ecf9a2a35d6c1f8d2c89", VoteDelegator.abi)

@pytest.fixture(scope="module")
def iBZRX(LoanTokenLogicStandard):
    return Contract.from_abi("iBZRX", "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    return Contract.from_abi("staking", address=stakingAddress, abi=StakingV1_1.abi)

@pytest.fixture(scope="module")
def TIMELOCK(Timelock):
    return Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi)

@pytest.fixture(scope="module")
def DAO(GovernorBravoDelegate, GovernorBravoDelegator, STAKINGv2,accounts, chain, TIMELOCK):
    oldDao = Contract.from_abi("governorBravoDelegator", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)
    GUARDIAN_MULTISIG = accounts.at("0x9B43a385E08EE3e4b402D4312dABD11296d09E93", True)
    daoProxy = Contract.from_abi("governorBravoDelegator", address="0x3133b4f4dcffc083724435784fefad510fa659c6", abi=GovernorBravoDelegator.abi)
    eta = TIMELOCK.delay()+ chain.time()+100
    oldDao.__queueSetTimelockPendingAdmin(daoProxy, eta, {"from": oldDao.guardian()})
    chain.sleep(TIMELOCK.delay() + 100)
    chain.mine()
    oldDao.__executeSetTimelockPendingAdmin(daoProxy, eta, {"from": oldDao.guardian()})
    dao = Contract.from_abi("governorBravoDelegator", address=daoProxy, abi=GovernorBravoDelegate.abi)
    dao.__acceptAdmin({"from": GUARDIAN_MULTISIG})
    assert dao.staking() == STAKINGv2
    assert dao.admin() == TIMELOCK
    assert TIMELOCK.admin() == dao
    return dao


@pytest.fixture(scope="module", autouse=True)
def STAKINGv2(accounts,TIMELOCK, StakingModularProxy, AdminSettings, StakeUnstake, StakingPausableGuardian, Voting, Rewards, interface, SUSHI_CHEF, OOKI_ETH_LP, BZRX, BZRXv2_CONVERTER, CRV3, POOL3_GAUGE, VOTE_DELEGATOR):
    SUSHI_CHEF.set(335, 1000, False, {'from': SUSHI_CHEF.owner()})
    SUSHI_CHEF.updatePool(335, {'from': SUSHI_CHEF.owner()})
    proxy = Contract.from_abi("STAKINGv2", address="0x16f179f5c344cc29672a58ea327a26f64b941a63", abi=StakingModularProxy.abi)
    staking = Contract.from_abi("STAKINGv2", address="0x16f179f5c344cc29672a58ea327a26f64b941a63", abi=interface.IStakingV2.abi)
    proxy.transferOwnership(TIMELOCK, {"from": proxy.owner()})
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

@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def TOKEN_SETTINGS(LoanTokenSettings):
    return Contract.from_abi(
        "loanToken", address="0x11ba2b39bc80464c14b7eea54d2ec93d8f60e7b8", abi=LoanTokenSettings.abi)
