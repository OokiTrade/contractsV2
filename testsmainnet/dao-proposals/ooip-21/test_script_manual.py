exec(open("./scripts/env/set-eth.py").read())

beforeTokenPrice = iUSDC.tokenPrice()
beforeTotalAssetBorrow = iUSDC.totalAssetBorrow()
beforeTotalAssetSupply = iUSDC.totalAssetSupply()
beforeTotalSupply = iUSDC.totalSupply()
print("beforeTokenPrice", beforeTokenPrice)
print("beforeTotalAssetBorrow", beforeTotalAssetBorrow)
print("beforeTotalAssetSupply", beforeTotalAssetSupply)
print("beforeTotalSupply", beforeTotalSupply)

exec(open("./scripts/dao-proposals/OOIP-21-pricefeed-update/before_proposal.py").read())

# TODO upgrade
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)

    if (iToken == iETH):
        iToken.setTarget(itokenImplWeth,{"from": TIMELOCK})
    else:
        iToken.setTarget(itokenImpl,{"from": TIMELOCK})
    iToken.consume(2**256-1, {"from": TIMELOCK})

BZX.replaceContract(lcl,{"from": TIMELOCK})
BZX.replaceContract(lc,{"from": TIMELOCK})

BZX.setPriceFeedContract(price_feed, {"from": TIMELOCK})

afterTokenPrice = iUSDC.tokenPrice()
afterTotalAssetBorrow = iUSDC.totalAssetBorrow()
afterTotalAssetSupply = iUSDC.totalAssetSupply()
afterTotalSupply = iUSDC.totalSupply()

print("afterTokenPrice", afterTokenPrice)
print("afterTotalAssetBorrow", afterTotalAssetBorrow)
print("afterTotalAssetSupply", afterTotalAssetSupply)
print("afterTotalSupply", afterTotalSupply)


BZX.toggleFunctionUnPause(BZX.borrowOrTradeFromPool.signature, {'from': GUARDIAN_MULTISIG})

iUSDC.borrow(0, 1e6, 90999999999, 90e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {"from": accounts[0], "value": Wei("90 ether")})

beforeTokenPrice = iUSDC.tokenPrice()
iUSDC.borrow(0, 1e6, 90999999999, 90e18, ZERO_ADDRESS, accounts[1], accounts[1], b'', {"from": accounts[1], "value": Wei("90 ether")})
afterTokenPrice = iUSDC.tokenPrice()
assert beforeTokenPrice <= afterTokenPrice

chain.mine(blocks=100)
holderUSDC = "0xcEe284F754E854890e311e3280b767F80797180d"
USDC.transfer(accounts[0], 200000e6, {"from": holderUSDC})
USDC.approve(BZX, 2**256-1, {"from": accounts[0]})

loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
loanId = loans[0][0]
BZX.closeWithDeposit(loanId, accounts[0], 200000e6, b'', {"from": accounts[0]})

beforeTokenPrice = iUSDC.tokenPrice()
iUSDC.marginTrade(0, 2e18, 0, 0.01*1e18, WETH, accounts[0], b'',{'from': accounts[0], "value": Wei("0.01 ether")})
afterTokenPrice = iUSDC.tokenPrice()
assert beforeTokenPrice <= afterTokenPrice

tokenPrice1 = iUSDC.tokenPrice()/1e18
USDC.transfer(iUSDC, 2000000* 10**6, {'from': "0x5B541d54e79052B34188db9A43F7b00ea8E2C4B1"})
tokenPrice2 = iUSDC.tokenPrice()/1e18
assert tokenPrice2 < tokenPrice1 * 1.0001
iUSDC.consume(2000000* 10**6, {'from' : GUARDIAN_MULTISIG})
tokenPrice3 =iUSDC.tokenPrice()/1e18
assert tokenPrice3 > 2 * tokenPrice1

# 1 weth test case mint and burn
assert iETH.internalBalanceOf() == WETH.balanceOf(iETH)
iETH.mintWithEther(accounts[0], {"from": accounts[0], "value": Wei("1 ether")})
assert iETH.internalBalanceOf() == WETH.balanceOf(iETH)
iETH.burnToEther(accounts[0], 1e18, {"from": accounts[0]})

# 2 borrow more 
assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)
iUSDC.borrow(0, 10000e6, 90999999999, 10e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {"from": accounts[0], "value": Wei("10 ether")})
loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
loanId = loans[0][0]

assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)
iUSDC.borrow(loanId, 1000e6, 90999999999, 1e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {"from": accounts[0], "value": Wei("1 ether")})
assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)

BZX.depositCollateral(loanId, 1e18, {"from": accounts[0], "value": Wei("1 ether")})
assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)
BZX.withdrawCollateral(loanId, accounts[0], 1e18, {"from": accounts[0]})
assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)
# 3 close half borrow
chain.mine(1000)
BZX.closeWithDeposit(loanId, accounts[0], 5000e6, b'', {"from": accounts[0]})
assert iUSDC.internalBalanceOf() == USDC.balanceOf(iUSDC)
assert False