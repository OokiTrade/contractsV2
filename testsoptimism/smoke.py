from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed

exec(open("./scripts/env/set-optimism.py").read())

iToken1 = iUSDC # arbitrun
Token1 = USDC # arbitrun, polygon
Token2 = WETH # arbitrun, polygon
iToken2 = iETH

def getTokenBalance(token, account):
    res = token.balanceOf(account)
    if(token == WETH):
        res = res + account.balance()
    return res

token1Decimals = Token1.decimals()
token2Decimals = Token2.decimals()

acct = accounts[0]
Token1.approve(iToken1, 2**256-1, {'from': acct})
Token1.approve(BZX, 2**256-1, {'from': acct})

Token1.transfer(acct, 1000* 10**token1Decimals, {'from': "0x2501c477d0a35545a387aa4a3eee4292a9a8b3f0"}) #optimism
iToken1.mint(acct, 500 * 10**token1Decimals, {'from': acct})

Token2.approve(iToken2, 2**256-1, {'from': acct})
Token2.approve(BZX, 2**256-1, {'from': acct})
Token2.transfer(acct, 20* 10**token2Decimals, {'from': "0xaa30d6bba6285d0585722e2440ff89e23ef68864"}) #optimism
iToken2.mint(acct, 10* 10**token2Decimals, {'from': acct})

dex_record = Contract.from_abi("DexRecords", BZX.swapsImpl(), DexRecords.abi)

route = encode_abi_packed(['address','uint24','address'],[Token1.address,500,Token2.address])
swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,chain.time()+10000,100,100)]])
openSendOut = encode_abi(['uint128','bytes[]'],[2,[encode_abi(['uint256','bytes'],[2,swap_payload])]])
Token2.approve(iToken1, 2**256-1, {'from':acct})


# iToken1.marginTrade(0, 2e18, 0, 0.01* 10**token2Decimals, Token2, acct, b'',{'from': acct})
# loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
# Token1BalanceBefore = getTokenBalance(Token1, acct)
# Token2BalanceBefore = getTokenBalance(Token2, acct)
# BZX.closeWithSwap(loans[0][0], acct,  2**256-1, True, b'', {'from':acct})
# Token1BalanceAfter = getTokenBalance(Token1, acct)
# Token2BalanceAfter = getTokenBalance(Token2, acct)
# print(Token1BalanceAfter - Token1BalanceBefore)
# print(Token2BalanceAfter - Token2BalanceBefore)
#
#
# iToken1.marginTrade(0, 2e18, 0, 0.01* 10**token2Decimals, Token2, acct, b'',{'from': acct})
# loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
# Token1BalanceBefore = getTokenBalance(Token1, acct)
# Token2BalanceBefore = getTokenBalance(Token2, acct)
# BZX.closeWithSwap(loans[0][0], acct,  2**256-1, False, b'', {'from':acct})
# Token1BalanceAfter = getTokenBalance(Token1, acct)
# Token2BalanceAfter = getTokenBalance(Token2, acct)
# print(Token1BalanceAfter - Token1BalanceBefore)
# print(Token2BalanceAfter - Token2BalanceBefore)

iToken1.marginTrade(0, 2e18, 0, 0.01* 10**token2Decimals, Token2, acct, openSendOut,{'from': acct})
loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
route = encode_abi_packed(['address','uint24','address'],[Token1.address,500,Token2.address])
swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,chain.time()+10000,loans[0][5],loans[0][5])]])
closeSendOut = encode_abi(['uint128','bytes[]'],[2,[encode_abi(['uint256','bytes'],[2,swap_payload])]])
Token1BalanceBefore = getTokenBalance(Token1, acct)
Token2BalanceBefore = getTokenBalance(Token2, acct)
BZX.closeWithSwap(loans[0][0], acct,  2**256-1, True, closeSendOut, {'from':acct})
Token1BalanceAfter = getTokenBalance(Token1, acct)
Token2BalanceAfter = getTokenBalance(Token2, acct)
assert (Token1BalanceAfter - Token1BalanceBefore == 0 )
assert (Token2BalanceAfter - Token2BalanceBefore > 0 )

iToken1.marginTrade(0, 2e18, 0, 0.01* 10**token2Decimals, Token2, acct, openSendOut,{'from': acct})
loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
route = encode_abi_packed(['address','uint24','address'],[Token2.address,500,Token1.address])
swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,chain.time()+10000,100,100)]])
closeSendOut = encode_abi(['uint128','bytes[]'],[2,[encode_abi(['uint256','bytes'],[2,swap_payload])]])
Token1BalanceBefore = getTokenBalance(Token1, acct)
Token2BalanceBefore = getTokenBalance(Token2, acct)
BZX.closeWithSwap(loans[0][0], acct,  loans[0][5], False, closeSendOut, {'from':acct})
Token1BalanceAfter = getTokenBalance(Token1, acct)
Token2BalanceAfter = getTokenBalance(Token2, acct)
assert (Token1BalanceAfter - Token1BalanceBefore > 0 )
assert (Token2BalanceAfter - Token2BalanceBefore == 0 )


iToken1.marginTrade(0, 2e18, 0, 0.01*10**token2Decimals, Token2, acct, openSendOut,{'from': acct})
loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
Token1BalanceBefore = getTokenBalance(Token1, acct)
Token2BalanceBefore = getTokenBalance(Token2, acct)
BZX.closeWithDeposit(loans[0][0], acct,  2**256-1, {'from':acct})
Token1BalanceAfter = getTokenBalance(Token1, acct)
Token2BalanceAfter = getTokenBalance(Token2, acct)
assert (Token1BalanceAfter - Token1BalanceBefore < 0 )
assert (Token2BalanceAfter - Token2BalanceBefore > 0 )


if(Token2 == WETH):
    iToken1.marginTrade(0, 2e18, 0, 0.01*10**token2Decimals, ZERO_ADDRESS, acct, openSendOut,{'from': acct, 'value': 0.01*10**token2Decimals})
    loans = BZX.getUserLoans(acct, 0,10, 0, False, False)
    Token1BalanceBefore = getTokenBalance(Token1, acct)
    Token2BalanceBefore = getTokenBalance(Token2, acct)
    BZX.closeWithDeposit(loans[0][0], acct,  2**256-1, {'from':acct})
    Token1BalanceAfter = getTokenBalance(Token1, acct)
    Token2BalanceAfter = getTokenBalance(Token2, acct)
    assert(Token1BalanceAfter - Token1BalanceBefore < 0)
    assert(Token2BalanceAfter - Token2BalanceBefore > 0)

