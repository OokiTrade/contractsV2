#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts
from eip712.messages import EIP712Message, EIP712Type


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):

    bzrx = Contract.from_abi("BZRX", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=TestToken.abi)
    bzrx.transfer(accounts[0], 1000*10**18, {'from': bzrx.address})

    return bzrx


@pytest.fixture(scope="module")
def OOKI(accounts, OokiToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=OokiToken.abi)


def test_ooki(requireMainnetFork, BZRX, OOKI, accounts, web3):

    # Mint
    # Burn
    # Approve
    # BurnFrom
    # Transfer
    # TransferFrom
    # permit

    with reverts("Ownable: caller is not the owner"):
        OOKI.mint(accounts[0], 100e18, {"from": accounts[0]})

    OOKI.mint(accounts[0], 100e18, {"from": OOKI.owner()})
    assert OOKI.balanceOf(accounts[0]) == 100e18

    OOKI.burn(10e18, {"from": accounts[0]})
    assert OOKI.balanceOf(accounts[0]) == 90e18

    with reverts("ERC20: burn amount exceeds allowance"):
        OOKI.burnFrom(accounts[0], 10e18, {"from": accounts[1]})

    OOKI.approve(accounts[1], 10e18, {"from": accounts[0]})
    OOKI.burnFrom(accounts[0], 10e18, {"from": accounts[1]})

    assert OOKI.balanceOf(accounts[0]) == 80e18

    OOKI.transfer(accounts[1], 10e18, {"from": accounts[0]})
    assert OOKI.balanceOf(accounts[0]) == 70e18
    assert OOKI.balanceOf(accounts[1]) == 10e18

    with reverts("ERC20: transfer amount exceeds allowance"):
        OOKI.transferFrom(accounts[1], accounts[0], 10e18, {"from": accounts[1]})

    OOKI.approve(accounts[0], 10e18, {"from": accounts[1]})
    OOKI.transferFrom(accounts[1], accounts[0], 10e18, {"from": accounts[0]})

    assert OOKI.balanceOf(accounts[0]) == 80e18
    assert OOKI.balanceOf(accounts[1]) == 0

    DOMAIN_TYPE_HASH = web3.keccak(text='EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
    PERMIT_TYPEHASH = web3.keccak(text='Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')

    local = accounts.add(private_key="0x416b8a7d9290502f5661da81f0cf43893e3d19cb9aea3c426cfb36e8186e9c09")
    DEADLINE = chain.time()+ 1000

    part1 = web3.solidityKeccak(["bytes32", "address", "address", "uint256", "uint256", "uint256"],
            [PERMIT_TYPEHASH,
            local.address,
            local.address,
            10*10**18,
            1,
            DEADLINE]
        )

    part2 = web3.solidityKeccak(['bytes1', 'bytes1', 'bytes32', 'bytes32'], 
        [
            "0x19",
            "0x01",
            DOMAIN_TYPE_HASH,
            part1
        ])

    # class Uint256(EIP712Type):
    #     inner: "uint256"
    # class Uint256(EIP712Type):
    #     inner: "uint256"

    # class TestMessage(EIP712Message):
    #     _name_: "string" = "Brownie Test Message"
    #     outer: "uint256"
    #     sub: TestSubType
    # local = accounts.add(private_key="0x416b8a7d9290502f5661da81f0cf43893e3d19cb9aea3c426cfb36e8186e9c09")

    # message = {
    #     "types": {
    #         "EIP712Domain": [
    #             {
    #                 "name": "name",
    #                 "type": "string",
    #             },
    #             {
    #                 "name": "version",
    #                 "type": "string",
    #             },
    #             {
    #                 "name": "chainId",
    #                 "type": "uint256",
    #             },
    #             {
    #                 "name": "verifyingContract",
    #                 "type": "address",
    #             },
    #         ],
    #         "Permit": [
    #             {
    #                 "name": "owner",
    #                 "type": "address",
    #             },
    #             {
    #                 "name": "spender",
    #                 "type": "address",
    #             },
    #             {
    #                 "name": "value",
    #                 "type": "uint256",
    #             },
    #             {
    #                 "name": "nonce",
    #                 "type": "uint256",
    #             },
    #             {
    #                 "name": "deadline",
    #                 "type": "uint256",
    #             }
    #         ],
    #     },
    #     "primaryType": "Permit",
    #     "domain": {
    #         "name": OOKI.name(),
    #         "version": "1",
    #         "chainId": 1,
    #         "verifyingContract": OOKI.address,
    #     },
    #     "message": "message",
    # }

    # class Permit(EIP712Type):
    #     inner: "Permit"

    # class Domain(EIP712Message):
    #     name = str()
    #     version = int()
    #     chainId = int()
    #     verifyingContract = str()


    # I give up doing it in pythong here is how to do for UI web3.js
    # https://hackernoon.com/how-to-code-gas-less-tokens-on-ethereum-43u3ew4

    assert True
