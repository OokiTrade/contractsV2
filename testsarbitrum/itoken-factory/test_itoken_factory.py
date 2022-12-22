from brownie import reverts, chain
import pytest

@pytest.fixture(scope="module")
def CUI(CurvedInterestRate):
    print("cui")
    return CurvedInterestRate.at("0x11e1251651bA36aD58B6bdaCaf11E5347a5D6e50")

@pytest.fixture(scope="module")
def FACTORY(LoanTokenFactory, accounts):
    f = LoanTokenFactory.deploy({"from":accounts[0]})
    return f

@pytest.fixture(scope="module")
def FACTORY_LOGIC(LoanTokenLogicFactory, accounts):
    print("factory_logic")
    return LoanTokenLogicFactory.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def ITOKEN_LOGIC(LoanTokenLogicStandard, accounts):
    print("itoken_logic")
    return LoanTokenLogicStandard.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def BZX(accounts, Contract, interface, TickMathV1, LoanOpenings, LoanSettings, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper, VolumeTracker, LoanClosings):
    tickMathV1 = accounts[0].deploy(TickMathV1)
    liquidationHelper = accounts[0].deploy(LiquidationHelper)
    accounts[0].deploy(VolumeTracker)

    lo = accounts[0].deploy(LoanOpenings)
    lc = accounts[0].deploy(LoanClosings)
    ls = accounts[0].deploy(LoanSettings)
    ps = accounts[0].deploy(ProtocolSettings)
    lcs = accounts[0].deploy(LoanClosingsLiquidation)
    lm = accounts[0].deploy(LoanMaintenance)

    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(lc, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    bzx.replaceContract(ps, {"from": bzx.owner()})
    bzx.replaceContract(lcs, {"from": bzx.owner()})
    bzx.replaceContract(lm, {"from": bzx.owner()})

    return bzx

#set factory, deploy iToken using random token, and deposit
def test_case1(FACTORY_LOGIC, FACTORY, CUI, ITOKEN_LOGIC, BZX, accounts, interface):
    FACTORY.setFlashLoanFeePercent(3e16, {"from":FACTORY.owner()})
    FACTORY.setTarget(FACTORY_LOGIC, {"from":FACTORY.owner()})
    FACTORY.setWhitelistTarget(ITOKEN_LOGIC, {"from":FACTORY.owner()})
    FACTORY.setRateHelper(CUI, {"from":FACTORY.owner()})
    #BZX.replaceContract(PROTOCOL_SETTINGS, {"from":BZX.owner()})
    BZX.setFactory(FACTORY, {"from":BZX.owner()})
    #BZX.replaceContract(LOAN_SETTINGS, {"from":BZX.owner()})
    FACTORY.addNewToken("0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a", {"from":accounts[1]})
    chain.sleep(120)
    chain.mine(1)
    FACTORY.setRateHelper("0x11e1251651bA36aD58B6bdaCaf11E5347a5D6e50", {"from":FACTORY.owner()})
    iTokenAddress = BZX.underlyingToLoanPool("0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a")
    iToken = interface.IToken(iTokenAddress)
    interface.IERC20("0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a").approve(iToken, 1e18, {"from":"0x80a9ae39310abf666a87c743d6ebbd0e8c42158e"})
    iToken.deposit(1e18, "0x80a9ae39310abf666a87c743d6ebbd0e8c42158e", {"from":"0x80a9ae39310abf666a87c743d6ebbd0e8c42158e"})
    assert(iToken.convertToAssets(iToken.balanceOf("0x80a9ae39310abf666a87c743d6ebbd0e8c42158e")) == 1e18)
    FACTORY.toggleFunctionPause("0x6e553f65", {"from":FACTORY.owner()})
    with reverts("paused"):
        iToken.deposit(1e18, "0x80a9ae39310abf666a87c743d6ebbd0e8c42158e", {"from":"0x80a9ae39310abf666a87c743d6ebbd0e8c42158e"})
    assert(FACTORY.isPaused("0x6e553f65") == True)