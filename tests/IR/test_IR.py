from brownie import *
ACC = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
def test_main():
    TickMath.deploy({'from':ACC})
    cc = TestTwapCurvedInterestRate.deploy({'from':ACC})
    cc.initOracle({'from':ACC})
    cc1 = CurvedInterestRate.deploy({'from':ACC})
    cc.setRateHelper(cc1.address, {'from':ACC})
    cc.writeIR(3e18, {'from':ACC})
    for i in range(60):
        borrows(cc)
    assert(False)

def borrows(cc):
    chain.sleep(60)
    chain.mine(1)
    print(cc.borrow(85e18, {'from':ACC}).return_value)