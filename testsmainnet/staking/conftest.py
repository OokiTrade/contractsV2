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
    


@pytest.fixture(scope="module")
def bzx(accounts, LoanTokenLogicStandard, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi, owner=accounts[0])
    # return Contract.from_explorer("0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f")

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass
