#!/usr/bin/python3

import pytest
from brownie import ZERO_ADDRESS, network, Contract, reverts, chain
from brownie.convert.datatypes import Wei
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import json
from eth_account import Account
from eth_account.messages import encode_structured_data
from eip712.messages import EIP712Message, EIP712Type
from brownie.network.account import LocalAccount
@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


@pytest.fixture(scope="module")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=interface.IBZx.abi)


@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", abi=TestToken.abi)


@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0x82af49447d8a07e3bd95bd0d56f35241523fbab1", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard, interface):
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("iUSDT", address="0xd103a2D544fC02481795b0B33eb21DE430f3eD23", abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})
    return itoken 


class Permit(EIP712Message):
    # One of the following must be used
    name_: "string"
    _version_: "string" = "1"
    chainId_: "uint256"
    verifyingContract_: "address"
    
    # These are the actual fields
    owner: "address"
    spender: "address"
    value: "uint256"
    nonce: "uint256"
    deadline: "uint256"
    
def test_permit(requireFork, USDT, iUSDT, accounts, BZX, interface):
    local = accounts.add(private_key="0x416b8a7d9290502f5661da81f0cf43893e3d19cb9aea3c426cfb36e8186e9c09")
    p = Permit(iUSDT.name(), chain.id, str(iUSDT), str(local), str(iUSDT), int(10e6), local.nonce, chain.height)
    signed_permit = local.sign_message(p)


    assert False
    
