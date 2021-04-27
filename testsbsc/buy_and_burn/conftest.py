#!/usr/bin/python3

import pytest
from brownie import Contract, network, Wei


@pytest.fixture(scope="class")
def requireBscFork():
    assert (network.show_active().find("binance-fork")>=0)


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xc47812857a74425e2039b57891a3dfcf51602d5d",
                      abi=interface.IBZx.abi, owner=accounts[0])

@pytest.fixture(scope="class")
def FEE_EXTRACTOR_BSC(accounts, FeeExtractor_BSC, Proxy_0_5):
    ext = FeeExtractor_BSC.deploy({"from": accounts[0]})
    proxy = Proxy_0_5.deploy(ext, {"from": accounts[0]})
    return Contract.from_abi("ext", address=proxy, abi=FeeExtractor_BSC.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def BGOV(accounts, BGovToken):
    return Contract.from_abi("bgov", address="0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF", abi=BGovToken.abi, owner=accounts[0])
