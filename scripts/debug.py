acct = accounts[0]
USDT.approve(iUSDT, 2**256-1, {'from': acct})
USDT.mint(acct, 10000e6, {'from': USDT.owner()})
iUSDT.mint(acct, 5000e6, {'from': acct})

USDC.approve(iUSDC, 2**256-1, {'from': acct})
USDC.mint(acct, 100000e6, {'from': USDC.owner()})
iUSDC.mint(acct, 5000e6, {'from': acct})


WETH.approve(iETH, 2**256-1, {'from': acct})
WETH.mint(acct, 20e18, {'from': WETH.owner()})
iETH.mint(acct, 10e18, {'from': acct})

WBTC.approve(iBTC, 2**256-1, {'from': acct})
WBTC.mint(acct, 10e8, {'from': WBTC.owner()})
iBTC.mint(acct, 1e8, {'from': acct})

WETH.approve(iUSDC, 2**256-1, {'from': acct})
WETH.approve(iUSDT, 2**256-1, {'from': acct})
WETH.approve(iBTC, 2**256-1, {'from': acct})
WBTC.approve(iUSDC, 2**256-1, {'from': acct})
iUSDC.borrow("", 500e6, 7884000, 0.5e18, WETH, acct, acct, b"", {'from': acct})
iUSDT.borrow("", 500e6, 7884000, 0.5e18, WETH, acct, acct, b"", {'from': acct})
iBTC.borrow("", 0.005e8, 7884000, 0.5e18, WETH, acct, acct, b"", {'from': acct})
trades = BZX.getUserLoans(acct, 0,10, 0,0,0)
interface.IERC20(trades[0][2]).approve(BZX, 2**256-1, {'from': acct})
BZX.closeWithDeposit(trades[0][0],acct,trades[0][4],{'from':acct})

iUSDC.marginTrade(0, 2e18, 0, 0.01e18, WETH, acct, b'',{'from': acct})




iBTC.marginTrade(0, 2e18, 0, 0.01e18, WETH, acct, b'',{'from': acct})
