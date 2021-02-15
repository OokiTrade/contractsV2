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

bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",
                        abi=interface.IBZx.abi, owner=accounts[0])

staking = Contract.from_abi("staking", address="0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4",
                        abi=StakingV1.abi, owner=accounts[0])
 
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
BPT = loadContractFromAbi(
    "0xe26A220a341EAca116bDa64cF9D5638A935ae629", "BPT", TestToken.abi)
print("11")


iUSDC = loadContractFromAbi(
    "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", TestToken.abi)


USDC = loadContractFromAbi(
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "USDC", TestToken.abi)

# print("mining some bzrx to addresses")
# # 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8

# mintAddresses = ["0x81b9284090501255C3a271c90100744Da99CC828",
#                  "0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe",
#                  "0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f",
#                  "0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3",
#                  "0xB78A81cd4FB3d727CD267d773491F5fC43BB3929",
#                  "0x1F9b46f3D89FEc66c09511d14bf1A813bCc96200"]

# # accounts[0].transfer(user, Wei('1 ether'))
# for user in mintAddresses:
#     print("mining for user:", user)
#     BZRX.transfer(user, 1000e18, {
#                   'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
#     vBZRX.transfer(user, 1000e18, {
#                    'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
#     iBZRX.transfer( user, 1000e18, {
#                    'from': "0xC02AbB7359bD145bf45ea01ebf8B64590d5b8992"})
#     BPT.transfer(user, 100e18, {
#                  'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
#     accounts[0].transfer(user, Wei('1 ether'))
# BZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
# BZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
# BZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})


# print("mining some vBZRX")
# #0x95beec2457838108089fcd0e059659a4e60b091a
# vBZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
# vBZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
# vBZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

# print("mining some iBZRX")
# #0xfe36046f6193d691f99e2c90153003f8938cfc41
# iBZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})
# iBZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})
# iBZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})

# print("mining some BPT")
# # 0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7
# BPT.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
# BPT.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
# BPT.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})

print("pre approve staking")
# accounts[0].transfer(to="0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", amount=Wei('1 ether'))
# accounts[0].transfer(to="0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", amount=Wei('1 ether'))


# BZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# vBZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# iBZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# BPT.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})

# BZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# vBZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# iBZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# BPT.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})


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
#     -u 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8\
#     -u 0x95beec2457838108089fcd0e059659a4e60b091a\
#     -u 0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe\
#     -u 0xfe36046f6193d691f99e2c90153003f8938cfc41\
#     -u 0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f\
#     -u 0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7\
#     -u 0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3



# ganache-cli --accounts 10 --hardfork istanbul --fork https://eth-mainnet.alchemyapi.io/v2/Cim1KnSYjNWTExhMWHMpewQUyatTbmfE --gasLimit 12000000 --mnemonic brownie --port 5458 --chainId 1 -h 0.0.0.0     -u 0xB7F72028D9b502Dc871C444363a7aC5A52546608    -u 0xb72b31907c1c95f3650b64b2469e08edacee5e8f    -u 0x56d811088235F11C8920698a204A5010a788f4b3    -u 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157    -u 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7    -u 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490    -u 0xe26A220a341EAca116bDa64cF9D5638A935ae629    -u 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8    -u 0x95beec2457838108089fcd0e059659a4e60b091a    -u 0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe    -u 0xfe36046f6193d691f99e2c90153003f8938cfc41    -u 0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f    -u 0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7    -u 0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3  --callGasLimit 8000000
