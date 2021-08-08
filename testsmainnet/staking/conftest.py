#!/usr/bin/python3

import pytest
import time
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


@pytest.fixture(scope="module", autouse=True)
def stakingV1(bzx, StakingProxy, StakingV1, accounts):

    proxy = StakingProxy.deploy(StakingV1.deploy(
        {"from": accounts[0]}), {"from": accounts[0]})
    staking = Contract.from_abi(
        "staking", address=proxy.address, abi=StakingV1.abi, owner=accounts[0])

    staking.setPaths([
        ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WETH -> BZRX
        ["0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WBTC -> WETH -> BZRX
        ["0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # AAVE -> WETH -> BZRX
        ["0xdd974D5C2e2928deA5F71b9825b8b646686BD200", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # KNC -> WETH -> BZRX
        ["0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # MKR -> WETH -> BZRX
        ["0x514910771AF9Ca656af840dff83E8264EcF986CA", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # LINK -> WETH -> BZRX
        ["0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "0x56d811088235F11C8920698a204A5010a788f4b3"],  # YFI -> WETH -> BZRX
    ])

    staking.setCurveApproval()

    assets = [
        "0x56d811088235F11C8920698a204A5010a788f4b3",  # BZRX
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # WETH
        "0x6B175474E89094C44Da98b954EedeAC495271d0F",  # DAI
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  # USDC
        "0xdAC17F958D2ee523a2206206994597C13D831ec7",  # USDT
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",  # WBTC
        "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",  # AAVE
        "0xdd974D5C2e2928deA5F71b9825b8b646686BD200",  # KNC
        "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",  # MKR
        "0x514910771AF9Ca656af840dff83E8264EcF986CA",  # LINK
        "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",  # YFI
    ]
    
    # for address in assets:
    #     staking.setUniswapApproval(address)
    #     time.sleep(1)
    staking.setFeeTokens(assets)
    staking.setFundsWallet(accounts[9])
    # bzx.withdrawFees(assets, accounts[8], 0, {'from': stakingV1})
    bzx.setFeesController(staking, {'from': bzx.owner()})
    staking.togglePause(False)


    staking.setMaxUniswapDisagreement(100*10**18, {'from': "0x66aB6D9362d4F35596279692F0251Db635165871", "allow_revert": 1})
    staking.setMaxCurveDisagreement(100*10**18, {'from': "0x66aB6D9362d4F35596279692F0251Db635165871", "allow_revert": 1})
    staking.setRewardPercent(50e18)
    staking.setCallerRewardDivisor(100)

    return staking
    # print("bzx owner", bzx.owner())
    # acct = accounts.at(bzx.owner(), force = True)
    # bzx.setFeesController(staking,  {'from': bzx.owner()})


@pytest.fixture(scope="module", autouse=True)
def stakingV1_1(bzx, StakingProxy, StakingV1_1,StakingV1, TestToken, accounts, LPT_OLD):

    old = Contract.from_abi("STAKING", '0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4', StakingV1.abi)
    LPT_OLD = Contract.from_abi("LPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)
    LPT_OLD.transfer(accounts[0], 10e18, {'from': '0xe95ebce2b02ee07def5ed6b53289801f7fc137a4'})
    LPT_OLD.approve(old, 2**256-1, {'from': accounts[0]})
    old.stake([LPT_OLD], [LPT_OLD.balanceOf(accounts[0])], {'from': accounts[0]})

    stakingProxy = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingProxy.abi)
    stakingImpl = StakingV1_1.deploy({'from': stakingProxy.owner()})
    stakingProxy.replaceImplementation(stakingImpl, {'from': stakingProxy.owner()})
    return Contract.from_abi("StakingV1_1", stakingProxy.address, StakingV1_1.abi, owner=accounts[9])


@pytest.fixture(scope="module")
def bzx(accounts, LoanTokenLogicStandard, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi, owner=accounts[0])
    # return Contract.from_explorer("0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f")

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass



@pytest.fixture(scope="module")
def vBZRX(accounts, BZRXVestingToken):
    vBZRX = loadContractFromAbi(
        "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX", BZRXVestingToken.abi)
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def LPT(accounts, TestToken, BZRX, WETH, interface):
    LPT = loadContractFromAbi("0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", "LPT", TestToken.abi)

    SUSHI_ROUTER = Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)

    quote = SUSHI_ROUTER.quote(1000*10**18, WETH.address, BZRX.address)
    quote1 = SUSHI_ROUTER.quote(10000*10**18, BZRX.address, WETH.address)
    BZRX.approve(SUSHI_ROUTER, 2**256-1, {'from': accounts[9]})
    WETH.approve(SUSHI_ROUTER, 2**256-1, {'from': accounts[9]})
    BZRX.transfer(accounts[9], 20000e18, {'from': BZRX})
    WETH.transfer(accounts[9], 20e18, {'from': WETH})

    SUSHI_ROUTER.addLiquidity(WETH,BZRX, quote1, BZRX.balanceOf(accounts[9]), 0, 0,  accounts[9], 10000000e18, {'from': accounts[9]})

    return LPT

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


# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract

@pytest.fixture(scope="module")
def setFeesController(bzx, stakingV1_1, accounts):
    bzx.setFeesController(stakingV1_1, {"from": bzx.owner()})
    assets = [
        "0x56d811088235F11C8920698a204A5010a788f4b3",  # BZRX
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # WETH
        "0x6B175474E89094C44Da98b954EedeAC495271d0F",  # DAI
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  # USDC
        "0xdAC17F958D2ee523a2206206994597C13D831ec7",  # USDT
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",  # WBTC
        "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",  # AAVE
        "0xdd974D5C2e2928deA5F71b9825b8b646686BD200",  # KNC
        "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",  # MKR
        "0x514910771AF9Ca656af840dff83E8264EcF986CA",  # LINK
        "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",  # YFI
    ]
    bzx.withdrawFees(assets, accounts[8], 0, {'from': stakingV1_1})


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

