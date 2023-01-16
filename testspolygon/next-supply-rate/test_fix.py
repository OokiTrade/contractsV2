from brownie import *

def test_t():
    IBZX = interface.IBZx('0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8')
    IUSDC = interface.IToken('0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d')
    newLogic = LoanTokenLogicStandard.deploy({'from':accounts[0]})
    IUSDC.setTarget(newLogic, {'from':IBZX.owner()})
    estValue = IUSDC.nextSupplyInterestRate(10000e6)
    print(IUSDC.supplyInterestRate())
    IUSDC.mint('0x2c1Bb88B698c6Cb4816685cf1995418786b5d0A5',10000e6, {'from':'0x2c1Bb88B698c6Cb4816685cf1995418786b5d0A5'})
    print(estValue)
    print(IUSDC.supplyInterestRate())
    assert(False)