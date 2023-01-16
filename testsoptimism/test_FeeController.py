from brownie import *
import pytest
from eth_abi import encode_abi
from eth_abi.packed import encode_abi_packed
@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1")

@pytest.fixture(scope="module")
def FEE_CONTROLLER(Contract, FeeExtractAndDistribute_Optimism, accounts, Proxy_0_8):
    controller = Proxy_0_8.deploy(FeeExtractAndDistribute_Optimism.deploy({"from":accounts[0]}), {"from":accounts[0]})
    controller = Contract.from_abi("FEE_CONTROLLER",controller.address, FeeExtractAndDistribute_Optimism.abi)
    USDT = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607"
    USDC = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58"
    ETH = "0x4200000000000000000000000000000000000006"
    tokensSupported = [USDT, USDC, ETH]
    USDT_PATH = encode_abi_packed(["address","uint24","address"],[USDT,500,USDC])
    USDC_PATH = b''
    ETH_PATH = encode_abi_packed(["address","uint24","address"],[ETH,500,USDC])
    controller.setFeeTokens(tokensSupported, [USDT_PATH, USDC_PATH, ETH_PATH], {"from":accounts[0]})
    controller.setBridge('0x9d39fc627a6d9d9f8c831c16995b209548cc3401', {"from":accounts[0]})
    controller.setBridgeApproval(USDC, {"from":accounts[0]})
    controller.setTreasuryWallet("0x8c02eDeE0c759df83e31861d11E6918Dd93427d2", {"from":accounts[0]})
    controller.setSlippage(30000, {"from":accounts[0]})
    return controller

def test_case1(BZX, accounts, FEE_CONTROLLER):
    BZX.setFeesController(FEE_CONTROLLER, {"from":BZX.owner()})
    FEE_CONTROLLER.sweepFees({"from":accounts[0]})