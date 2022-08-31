from distutils.sysconfig import EXEC_PREFIX
from brownie import *
import pytest
from eth_abi import encode_abi

@pytest.fixture(scope="module")
def TIMELOCKRECEIVER(TimelockReceiver, accounts):
    return TimelockReceiver.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def EXECUTOR(Executor, accounts):
    return Executor.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def MESSAGEBUS():
    return "0xaFDb9C40C7144022811F034EE07Ce2E110093fe6"

@pytest.fixture(scope="module")
def MULTISIG():
    return "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"

def test_case(accounts, TIMELOCKRECEIVER, EXECUTOR, BZX, MESSAGEBUS, MULTISIG):
    TIMELOCKRECEIVER.setMessageBus(MESSAGEBUS, {"from":accounts[0]})
    TIMELOCKRECEIVER.setTimelockDistributor(accounts[0], {"from":accounts[0]})
    TIMELOCKRECEIVER.setExecutor(EXECUTOR, {"from":accounts[0]})
    TIMELOCKRECEIVER.transferOwnership(MULTISIG, {"from":accounts[0]})
    BZX.transferOwnership(EXECUTOR, {"from":BZX.owner()})
    EXECUTOR.transferOwnership(TIMELOCKRECEIVER, {"from":EXECUTOR.owner()})
    print(BZX.setFeesController.encode_input(MULTISIG))
    print(BZX.setFeesController.encode_input(MULTISIG)[2:])
    txns = [(BZX.address,bytes.fromhex(BZX.setFeesController.encode_input(MULTISIG)[2:]),0)] #test txn on owner only functionality
    data = encode_abi(['(address,bytes,uint256)[]'],[txns])
    print(TIMELOCKRECEIVER.executeMessage(accounts[0], 1, data, accounts[0], {"from":MESSAGEBUS}).return_value)
    assert(BZX.feesController() == MULTISIG)
