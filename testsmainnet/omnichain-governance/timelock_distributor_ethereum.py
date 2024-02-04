from brownie import *
import pytest

@pytest.fixture(scope="module")
def TIMELOCKMESSAGEDISTRIBUTOR(TimelockMessageDistributor, accounts):
    return TimelockMessageDistributor.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def MESSAGEBUS():
    return "0x4066D196A423b2b3B8B054f4F40efB47a74E200C"

def test_case(TIMELOCKMESSAGEDISTRIBUTOR, MESSAGEBUS):
    tLockMsg = TIMELOCKMESSAGEDISTRIBUTOR
    tLockMsg.setMessageBus(MESSAGEBUS, {"from":tLockMsg.owner()})
    tLockMsg.setDestForID(137, "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", {"from":tLockMsg.owner()}) #random dest address just for testing
    message = "Testing Message"
    message = message.encode("utf-8")
    getCost = tLockMsg.computeFee(message)
    tLockMsg.sendMessageToChain(137, message, {"value":getCost, "from":tLockMsg.owner()})
    assert(tLockMsg.chainIdToDest(137) == "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")