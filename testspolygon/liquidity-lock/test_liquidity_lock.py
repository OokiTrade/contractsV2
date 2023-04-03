from brownie import *
import pytest
from brownie import reverts
@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def TREASURY():
    return "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"

@pytest.fixture(scope="module")
def LIQUIDITYLOCK(LiquidityLock, BZX, TREASURY):
    return LiquidityLock.deploy(BZX, TREASURY, {"from":accounts[0]})

@pytest.fixture(scope="module")
def USDC(interface):
    return interface.IERC20("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")

@pytest.fixture(scope="module")
def IUSDC(interface):
    return interface.IToken("0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d")

#successful test
def test_case1(LIQUIDITYLOCK, BZX, interface, USDC, IUSDC):
    USDC.transfer(accounts[0], 200e6, {"from":"0x06959153b974d0d5fdfd87d561db6d8d4fa0bb0b"})
    USDC.transfer(accounts[1], 10e6, {"from":"0x06959153b974d0d5fdfd87d561db6d8d4fa0bb0b"})
    USDC.approve(LIQUIDITYLOCK, 500e6, {"from":accounts[0]})
    USDC.approve(LIQUIDITYLOCK, 100e6, {"from":accounts[1]})
    LIQUIDITYLOCK.increaseClaimableBonus([USDC], [10e6], {"from":accounts[1]})
    #max lock time set here is 45 days
    #minimum guaranteed APR is 1%
    #it is increased by 0.5% for every 30 days of lockup
    LIQUIDITYLOCK.updateSettings(USDC, 1e18, 19025875190300, 3942000, {"from":accounts[0]})
    LIQUIDITYLOCK.setLockCap([USDC], [109e6], {"from":accounts[0]})
    LIQUIDITYLOCK.setApprovals([USDC], [IUSDC], {"from":accounts[0]})
    month_1 = 2628000

    claim_code = LIQUIDITYLOCK.lock(USDC, 100e6, chain.time()+month_1, {"from":accounts[0]}).return_value
    print(claim_code)
    claimData = LIQUIDITYLOCK.claims(claim_code)
    assert claimData[0] == IUSDC.address
    assert claimData[2] > chain.time()
    assert claimData[3] > 0
    assert claimData[4] == 100e6
    chain.sleep(int(month_1/2))
    chain.mine()
    LIQUIDITYLOCK.increaseLockup(claim_code, 4e6, {"from":accounts[0]})
    claimData1 = LIQUIDITYLOCK.claims(claim_code)
    assert claimData[0] == IUSDC.address
    assert claimData[2] > chain.time()
    assert claimData1[3] > claimData[3]
    assert claimData1[4] > 104e6
    chain.sleep(month_1+100)
    chain.mine()
    LIQUIDITYLOCK.unlock(claim_code, {"from":accounts[0]})
    assert USDC.balanceOf(accounts[0]) >= (96e6+100e6*(1.00125)+4e6*(1.000625))

#throw error because over lock cap
def test_case2(LIQUIDITYLOCK, BZX, interface, USDC, IUSDC):
    with reverts("over committed"):
        LIQUIDITYLOCK.lock(USDC, 110e6, chain.time()+100, {"from":accounts[0]})

#throw error on ending time
def test_case3(LIQUIDITYLOCK, BZX, interface, USDC, IUSDC):
    with reverts("invalid ending time"):
        LIQUIDITYLOCK.lock(USDC, 100e6, chain.time()-1000, {"from":accounts[0]})
    with reverts("invalid ending time"):
        LIQUIDITYLOCK.lock(USDC, 100e6, chain.time()+3948000, {"from":accounts[0]})

#throw error on id, try to pre-claim, and claim from wrong wallet
def test_case4(LIQUIDITYLOCK, BZX, interface, USDC, IUSDC):
    unlock_time = chain.time()+2628000
    claim_code = LIQUIDITYLOCK.lock(USDC, 1e6, unlock_time, {"from":accounts[0]}).return_value
    with reverts("already used id"):
        LIQUIDITYLOCK.lock(USDC, 1e6, unlock_time, {"from":accounts[0]})
    with reverts("not unlocked yet"):
        LIQUIDITYLOCK.unlock(claim_code, {"from":accounts[0]})
    with reverts("unauthorized"):
        LIQUIDITYLOCK.unlock(claim_code, {"from":accounts[1]})

#double claim
def test_case5(LIQUIDITYLOCK, BZX, interface, USDC, IUSDC):
    unlock_time = chain.time()+2628100
    claim_code = LIQUIDITYLOCK.lock(USDC, 1e6, unlock_time, {"from":accounts[0]}).return_value
    chain.sleep(2629100)
    chain.mine()
    LIQUIDITYLOCK.unlock(claim_code, {"from":accounts[0]})
    with reverts("19"):
        LIQUIDITYLOCK.unlock(claim_code, {"from":accounts[0]})
