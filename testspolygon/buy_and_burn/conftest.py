#!/usr/bin/python3

import pytest
from brownie import Contract, network, Wei


@pytest.fixture(scope="class")
def requireFork():
    assert (network.show_active().find("matic-main4-fork")>=0)


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B",
                      abi=interface.IBZx.abi, owner=accounts[0])

@pytest.fixture(scope="class")
def FEE_EXTRACTOR_MATIC(accounts, FeeExtractAndDistribute_Polygon, Proxy_0_5):
    ext = FeeExtractAndDistribute_Polygon.deploy({"from": accounts[0]})
    proxy = Proxy_0_5.deploy(ext, {"from": accounts[0]})
    return Contract.from_abi("ext", address=proxy, abi=FeeExtractAndDistribute_Polygon.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def GOV(accounts, GovToken):
    return Contract.from_abi("gov", address="0xd5d84e75f48E75f01fb2EB6dFD8eA148eE3d0FEb", abi=GovToken.abi, owner=accounts[0])
