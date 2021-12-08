#!/usr/bin/python3

import pytest
import time
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


@pytest.fixture(scope="module", autouse=True)
def stakingAdminSettings(bzx, StakingAdminSettings, accounts):
    res = StakingAdminSettings.deploy({'from': accounts[0]})
    return res;

@pytest.fixture(scope="module")
def bzx(accounts, LoanTokenLogicStandard, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi, owner=accounts[0])
    # return Contract.from_explorer("0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f")

@pytest.fixture(scope="module")
def stakingVoteDelegator(accounts, StakingVoteDelegator,Proxy_0_5):
    stakingVotedelegatorProxy = Contract.from_abi("proxy", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", Proxy_0_5.abi)
    stakingVotedelegatorImpl = StakingVoteDelegator.deploy({'from': accounts[0]})
    stakingVotedelegatorProxy.replaceImplementation(stakingVotedelegatorImpl, {'from': stakingVotedelegatorProxy.owner()})

    return Contract.from_abi("StakingVoteDelegator", stakingVotedelegatorProxy, StakingVoteDelegator.abi)

@pytest.fixture(scope="module")
def governance(accounts, GovernorBravoDelegate):
    return Contract.from_abi("governorBravoDelegator", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)

@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi, owner=accounts[0])


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", address=bzx.underlyingToLoanPool(USDC.address), abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="module", autouse=True)
def stakingV1_1(bzx, StakingProxy, StakingV1_1, POOL3Gauge, accounts, POOL3, stakingAdminSettings, stakingVoteDelegator):
    stakingProxy = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingProxy.abi)
    stakingImpl = StakingV1_1.deploy({'from': stakingProxy.owner()})
    stakingProxy.replaceImplementation(stakingImpl, {'from': stakingProxy.owner()})

    res = Contract.from_abi("StakingV1_1", stakingProxy.address, StakingV1_1.abi, owner=accounts[9])
    return res;

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass

@pytest.fixture(scope="module")
def CRV(accounts, TestToken):
    return Contract.from_abi("CRV", "0xD533a949740bb3306d119CC777fa900bA034cd52", TestToken.abi)


@pytest.fixture(scope="module")
def POOL3Gauge(interface):
   return Contract.from_abi("POOL3Gauge", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi)


@pytest.fixture(scope="module")
def vBZRX(accounts, BZRXVestingToken):
    vBZRX = loadContractFromAbi(
        "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX", BZRXVestingToken.abi)
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def LPT(accounts, TestToken, BZRX, WETH,router, interface, stakingV1_1, SUSHI_CHEF):
    LPT = loadContractFromAbi("0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", "LPT", TestToken.abi)
    router = Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)
    quote = router.quote(1000*10**18, WETH.address, BZRX.address)
    quote1 = router.quote(10000*10**18, BZRX.address, WETH.address)
    BZRX.approve(router, 2**256-1, {'from': accounts[9]})
    WETH.approve(router, 2**256-1, {'from': accounts[9]})
    BZRX.transfer(accounts[9], 20000e18, {'from': BZRX})
    WETH.transfer(accounts[9], 20e18, {'from': WETH})

    router.addLiquidity(WETH,BZRX, quote1, BZRX.balanceOf(accounts[9]), 0, 0,  accounts[9], 10000000e18, {'from': accounts[9]})
    return LPT

@pytest.fixture(scope="module")
def SUSHI_CHEF(accounts, interface, stakingV1_1):
    chef = Contract.from_abi("CHEF", "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd", interface.IMasterChefSushi.abi)
    return chef


@pytest.fixture(scope="module")
def LPT_OLD(accounts, TestToken):
    LPT = loadContractFromAbi(
        "0xe26A220a341EAca116bDa64cF9D5638A935ae629", "LPT", TestToken.abi)
    return LPT


@pytest.fixture(scope="module")
def POOL3(accounts, TestToken):
    POOL3 = loadContractFromAbi(
        "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", "3Crv", TestToken.abi)
    return POOL3


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    iUSDC = loadContractFromAbi(
        "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", LoanTokenLogicStandard.abi)
    return iUSDC


@pytest.fixture(scope="module")
def WETH(accounts, TestWeth):
    WETH = loadContractFromAbi(
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH", TestWeth.abi)
    return WETH


@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    USDC = loadContractFromAbi(
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "USDC", TestToken.abi)
    return USDC


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    BZRX = loadContractFromAbi(
        "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX", TestToken.abi)
    BZRX.transfer(accounts[0], 1000*10**18, {'from': BZRX.address})
    return BZRX


@pytest.fixture(scope="module")
def iBZRX(accounts, BZRX, LoanTokenLogicStandard):
    iBZRX = loadContractFromAbi(
        "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", "iBZRX", LoanTokenLogicStandard.abi)
    BZRX.approve(iBZRX, 10*10**50, {'from': accounts[0]})
    iBZRX.mint(accounts[0], 100*10**18, {'from': accounts[0]})
    return iBZRX


@pytest.fixture(scope="module")
def SUSHI(TestToken):
     return Contract.from_abi("SUSHI", "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2", TestToken.abi)

@pytest.fixture(scope="module")
def router(TestToken, interface):
    return Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)

@pytest.fixture(scope="module")
def fees_extractor(accounts, bzx, stakingV1_1, FeeExtractAndDistribute_ETH, Proxy):

    feesExtractorImpl = FeeExtractAndDistribute_ETH.deploy({'from': stakingV1_1.owner()})
    proxy = Proxy.deploy(feesExtractorImpl, {'from': stakingV1_1.owner()})

    res = Contract.from_abi("FEE_EXTRACTOR", proxy.address, FeeExtractAndDistribute_ETH.abi)
    bzx.setFeesController(proxy, {'from': bzx.owner()})
    res.setPaths([
        ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WETH -> BZRX
        ["0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WBTC -> WETH -> BZRX
        ["0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # AAVE -> WETH -> BZRX
        # ["0xdd974D5C2e2928deA5F71b9825b8b646686BD200", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        #     "0x56d811088235F11C8920698a204A5010a788f4b3"]  # KNC -> WETH -> BZRX
        ["0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # MKR -> WETH -> BZRX
        ["0x514910771AF9Ca656af840dff83E8264EcF986CA", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # LINK -> WETH -> BZRX
        ["0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # YFI -> WETH -> BZRX
        ["0xc00e94cb662c3520282e6f5717214004a7f26888", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # COMP -> WETH -> BZRX,
        #["0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        #    "0x56d811088235F11C8920698a204A5010a788f4b3"],  # LRC -> WETH -> BZRX <--- no liquidity on sushi
        ["0x1f9840a85d5af5bf1d1762f925bdaddc4201f984", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "0x56d811088235F11C8920698a204A5010a788f4b3"],  # UNI -> WETH -> BZRX
    ], {'from': bzx.owner()})

    res.setApprovals({'from': res.owner()})

    return res


# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

