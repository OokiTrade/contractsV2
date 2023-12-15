exec(open("./scripts/env/set-eth.py").read())

beforeTokenPrice = iUSDC.tokenPrice()
beforeTotalAssetBorrow = iUSDC.totalAssetBorrow()
beforeTotalAssetSupply = iUSDC.totalAssetSupply()
beforeTotalSupply = iUSDC.totalSupply()
exec(open("./scripts/dao-proposals/OOIP-21-pricefeed-update/before_proposal.py").read())


afterTokenPrice = iUSDC.tokenPrice()
afterTotalAssetBorrow = iUSDC.totalAssetBorrow()
afterTotalAssetSupply = iUSDC.totalAssetSupply()
afterTotalSupply = iUSDC.totalSupply()



BZX.toggleFunctionUnPause(BZX.borrowOrTradeFromPool.signature, {'from': GUARDIAN_MULTISIG})


iUSDC.borrow(0, 100000e6, 90999999999, 90e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {"from": accounts[0], "value": Wei("90 ether")})

chain.mine(blocks=100)
holderUSDC = "0xcEe284F754E854890e311e3280b767F80797180d"
USDC.transfer(accounts[0], 200000e6, {"from": holderUSDC})
USDC.approve(BZX, 2**256-1, {"from": accounts[0]})

loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
loanId = loans[0][0]
BZX.closeWithDeposit(loanId, accounts[0], 200000e6, b'', {"from": accounts[0]})

assert False