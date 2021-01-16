#!/usr/bin/python3

import pytest
import time
from brownie import *
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

global iBZRX, BZRX, vBZRX, CURVE3POOL, CURVE3CRV

def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract

# def main():
print("1")
stakingImpl = accounts[0].deploy(StakingV1)
proxy = accounts[0].deploy(StakingProxy, stakingImpl, allow_revert=1)
staking = Contract.from_abi(
    "staking", address=proxy.address, abi=StakingV1.abi, owner=accounts[0])
print("2")
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
print("3")
staking.setCurveApproval()
print("4")
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

for address in assets:
    print("4", address)
    staking.setUniswapApproval(address)
    time.sleep(1)
print("4.1")
staking.setFeeTokens(assets)
print("4.2")
staking.setFundsWallet(accounts[9])
# bzx.withdrawFees(assets, accounts[8], 0, {'from': stakingV1})
bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi, owner=accounts[0])
print("4.3")
bzx.setFeesController(staking, {'from': bzx.owner()})
print("4.4")
staking.unPause()
print("5")

global iBZRX, BZRX, vBZRX, CURVE3POOL, CURVE3CRV
vBZRX = loadContractFromAbi(
    "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX", BZRXVestingToken.abi)
print("6")
BZRX = loadContractFromAbi(
    "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX", TestToken.abi)
print("7")
iBZRX = loadContractFromAbi(
    "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", "iBZRX", LoanTokenLogicStandard.abi)
print("8")
CURVE3POOL = loadContractFromAbi(
    "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7", "CURVE3POOL", TestToken.abi)
print("9")
CURVE3CRV = loadContractFromAbi(
    "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", "CURVE3CRV", TestToken.abi)
print("10")
LPT = loadContractFromAbi(
    "0xe26A220a341EAca116bDa64cF9D5638A935ae629", "LPT", TestToken.abi)
print("11")
# Run command below
# exec(open("./scripts/staking-fork.py").read())
# brownie networks add Ethereum staging chainid=1 host=http://35.174.43.93:5458

# ganache-cli --accounts 10 --hardfork istanbul --fork https://eth-mainnet.alchemyapi.io/v2/1-sHvdVH_hHp9jvOiVp4LqqXg0_sGhPK --gasLimit 12000000 --mnemonic brownie --port 8545 --chainId 1 -h 0.0.0.0 -v -u "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
# https://eth-mainnet.alchemyapi.io/v2/Cim1KnSYjNWTExhMWHMpewQUyatTbmfE

# ganache-cli --accounts 10 --hardfork istanbul --fork https://eth-mainnet.alchemyapi.io/v2/Cim1KnSYjNWTExhMWHMpewQUyatTbmfE --gasLimit 12000000 --mnemonic brownie --port 5458 --chainId 1 -h 0.0.0.0 \
#     -u 0xB7F72028D9b502Dc871C444363a7aC5A52546608\
#     -u 0xb72b31907c1c95f3650b64b2469e08edacee5e8f\
#     -u 0x56d811088235F11C8920698a204A5010a788f4b3\
#     -u 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157\
#     -u 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7\
#     -u 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490\
#     -u 0xe26A220a341EAca116bDa64cF9D5638A935ae629\
#     -u 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8