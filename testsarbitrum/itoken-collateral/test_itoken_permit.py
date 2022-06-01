#!/usr/bin/python3
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
from brownie.convert.datatypes import *
from brownie import web3

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


class Permit():
    def __init__(self, name, chainId, verifyingContract, owner, spender, value, nonce, deadline, domain_separator):
        self.name = name
        self.chainId = chainId
        self.verifyingContract = str(verifyingContract)
        self.owner = str(owner)
        self.spender = str(spender)
        self.value = int(value)
        self.nonce = nonce
        self.deadline = deadline
        self.permit_typehash = HexString("0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9", "bytes32")
        self.domain_separator = domain_separator

    def sign_message(self, local: LocalAccount):
        domainData = web3.sha3(encode_abi(["bytes32", "address", "address", "uint256", "uint256", "uint256"],
                                          [self.permit_typehash, str(local), self.verifyingContract, self.value, self.nonce, self.deadline]))
        digest = web3.solidityKeccak(['bytes1', 'bytes1', 'bytes32', 'bytes32'], [b'\x19', b'\x01', self.domain_separator, domainData])
        signed_permit = web3.eth.account.signHash(digest, local.private_key)
        return signed_permit


def test_permit(requireFork, USDT, iUSDT, accounts, BZX, interface, web3):
    local = accounts.add(private_key="0x416b8a7d9290502f5661da81f0cf43893e3d19cb9aea3c426cfb36e8186e9c09")

    p = Permit(iUSDT.name(), chain.id, iUSDT, local, iUSDT, int(10e6), local.nonce, chain.time()+1000, iUSDT.DOMAIN_SEPARATOR())
    signed_permit = p.sign_message(local)
    # iUSDT.permit(p.owner, p.spender, p.value, p.deadline, signed_permit.v, signed_permit.r, signed_permit.s, {"from": local})
    USDT.transfer(local, 1000e6, {'from': "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641"})
    USDT.approve(iUSDT, 2**256-1, {"from": local})
    iUSDT.mint(local, 1000e6, {"from": local})
    assert False


def test_borrow_and_close_itoken_with_permit():
    assert False

def test_liquidate_itoken():
    assert False

def test_guardian_create_inewitoken():
    # TODO think about disabling loanParameters
    assert False

    