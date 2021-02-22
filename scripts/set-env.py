
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
    "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", LoanTokenLogicStandard.abi)


USDC = loadContractFromAbi(
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "USDC", TestToken.abi)
