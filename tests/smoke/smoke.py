
from brownie import *
import pytest

holders_1 = {
    'DAI': '0x66f62574ab04989737228d18c3624f7fc1edae14',
    #'WETH' : '0xf04a5cc80b1e94c69b48f5ee68a08cd2f09a7c3e',
    'USDC': '0xF977814e90dA44bFA03b6295A0616a897441aceC',
    # 'WBTC': '0x218b95be3ed99141b0144dba6ce88807c4ad7c09',
    # # 'LRC' : '0x46f80018211d5cbbc988e853a8683501fca4ee9b',
    # # 'KNC' : '0x97f991971a37d4ca58064e6a98fc563f03a71e5c',
    # 'MKR' : '0xa9dda2045d140eb7ccd30c4ef6b9901ccb279793', #Deprecated
    # 'LINK': '0x7182bdeacab178a1c5a14502d532f8b2b7cf4285',
    # # 'YFI': '0xe174c389249b0e3a4ec84d2a5667aa4920cb77de',
    # # 'AAVE': '0x3744da57184575064838bbc87a0fc791f5e39ea2',
    # # 'UNI': '0x0ec9e8aa56e0425b60dee347c8efbad959579d0f',
    # 'COMP': '0xfbe18f066f9583dac19c88444bc2005c99881e56',
    # 'OOKI': '0x16f179f5c344cc29672a58ea327a26f64b941a63',
    # 'APE': '0x91951fa186a77788197975ed58980221872a3352',
}

def holders():
    return holders_1


@pytest.fixture(scope="module")
def REGISTRY(TokenRegistry):
    return Contract.from_abi("TOKEN_REGISTRY", "0xf0E474592B455579Fe580D610b846BdBb529C6F7", TokenRegistry.abi)


@pytest.fixture(scope="module")
def BZX(interface):
    return Contract.from_abi("BZX", "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", interface.IBZx.abi)

@pytest.fixture(scope="module")
def HELPER(interface):
    return Contract.from_abi("HELPER", "0xb887f5b81deec1e271b06257f138e5a9d422bc8c", HelperImpl.abi)



@pytest.fixture(scope="module")
def ITOKENS(REGISTRY):
    res = {}
    list = REGISTRY.getTokens(0, 50)
    for l in list:
        iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
        res[iTokenTemp.symbol()] = iTokenTemp
    return res

@pytest.fixture(scope="module")
def TOKENS(REGISTRY):
    res = {}
    list = REGISTRY.getTokens(0, 50)
    for l in list:
        underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
        if (l[1] == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"):
            res["MKR"] = underlyingTemp # MRK has some fun symbol()
        else:
            res[underlyingTemp.symbol()] = underlyingTemp
    return res



def pytest_generate_tests(metafunc):
    res = []
    for i in holders().keys():
        for j in holders().keys():
            if(i == j):
                res.append(['mint', 'i'+i, j])
            else:
                res.append(['borrow', 'i'+i, j])
                res.append(['trade', 'i'+i, j])

    print(res)

    metafunc.parametrize("input", res)
    return res



def get_amount(loanToken, USDT, interface, BZX):
    print('==================')
    decimals = interface.IERC20Detailed(loanToken).decimals()
    print(loanToken.symbol())
    print(decimals)
    pricefeeds = interface.IPriceFeeds(BZX.priceFeeds())
    usdtPricefeed = interface.IPriceFeedsExt(pricefeeds.pricesFeeds(USDT.address))
    pricefeed = interface.IPriceFeedsExt(pricefeeds.pricesFeeds(loanToken))
    currentPrice = pricefeed.latestAnswer() / (usdtPricefeed.latestAnswer())  # current token price in USDT
    print(currentPrice)
    print(loanToken.symbol(), " = ", currentPrice)
    print(10 ** decimals * 10 / currentPrice)
    return 10 ** decimals * 10 / currentPrice  # Operating ammount


def mint(itoken, loanToken, amount, account):
    print("Mint: ", amount, loanToken.symbol())
    if (loanToken.allowance(account, itoken) == 0):
        loanToken.approve(itoken, 2**256-1, {'from': account})
    itoken.mint(amount, account, {'from': account})
    assert history[-1].status.name == 'Confirmed'

def burn(itoken, amount, account):
    print("Burn: ", amount, itoken.symbol())
    itoken.burn(amount, account, {'from': account})
    assert history[-1].status.name == 'Confirmed'


def t_mint(itoken, loanToken, amount, account):
    iTokenBalanceBefore = itoken.balanceOf(account)
    mint(itoken, loanToken, amount, account)
    iTokenBalanceAfter = itoken.balanceOf(account)
    assert iTokenBalanceBefore < iTokenBalanceAfter
    tokenBalanceBefore = loanToken.balanceOf(account)
    burn(itoken, iTokenBalanceAfter, account)
    tokenBalanceAfter = loanToken.balanceOf(account)
    assert itoken.balanceOf(account) == 0
    assert tokenBalanceAfter > tokenBalanceBefore


def borrow(itoken, loanToken, collateral, amount, account, isNativeCollateral, HELPER):
    collateralAmount = HELPER.getDepositAmountForBorrow(amount, loanToken, collateral)
    assert collateralAmount > 0
    print("Borrow ", amount, loanToken.symbol(), " collateral", collateralAmount, collateral.symbol())
    value = 0 if not isNativeCollateral else amount
    print("value: ", value)
    collateralAddress = collateral.address if not isNativeCollateral else "0x0000000000000000000000000000000000000000"
    print("collateralAddress: ", collateralAddress)
    itoken.borrow(0x0000000000000000000000000000000000000000000000000000000000000000, amount, 7884000, collateralAmount, collateralAddress, account.address, account.address,  b'', {'value': value, 'from': account})
    assert history[-1].status.name == 'Confirmed'


def closeWithDeposit(loan, token, account, isNative, BZX):
    if (token.allowance(account, BZX) == 0):
        token.approve(BZX, 2**256-1, {'from': account})
    print("closeWithDeposit")
    amount = (int)(loan[4] * 1.01)
    value = 0 if not isNative else amount
    print("loan before: ", loan)
    print("Value: ", value)
    BZX.closeWithDeposit(loan[0], account, amount, b'', {'from': account, 'value': value})
    assert history[-1].status.name == 'Confirmed'
    print("loan after: ", BZX.getLoan(loan[0]))


def t_borrow(loanToken, itoken, collateral, account, isNativeToken, isNativeCollateral, USDT, interface, BZX, HELPER):
    amount = get_amount(loanToken, USDT, interface, BZX)
    if (collateral.allowance(account, itoken) == 0):
        collateral.approve(itoken, 2**256-1, {'from': account})
    # BORROW
    account = accounts.at(account)

    tokenBalanceBefore = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceBefore = collateral.balanceOf(account) if not isNativeCollateral else account.balance()

    print("itoken: ", itoken.symbol())
    print("token: ", loanToken.symbol())
    print("isNativeToken: ", isNativeToken)
    print("collateral: ", collateral.symbol())
    print("isNativeCollateral: ", isNativeCollateral)
    print("borrow amount: ", amount)
    print("account: ", account)

    print("tokenBalanceBefore: ", tokenBalanceBefore)
    print("collatralTokenBalanceBefore: ", collatralTokenBalanceBefore)
    borrow(itoken, loanToken, collateral, amount, account, isNativeCollateral, HELPER)
    borrow(itoken, loanToken, collateral, amount, account, isNativeCollateral, HELPER)

    tokenBalanceAfter = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceAfter = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("tokenBalanceAfter: ", tokenBalanceAfter)
    print("collatralTokenBalanceAfter: ", collatralTokenBalanceAfter)
    assert amount * 2 / (tokenBalanceAfter - tokenBalanceBefore) >= 0.9
    assert tokenBalanceBefore < tokenBalanceAfter
    assert collatralTokenBalanceBefore > collatralTokenBalanceAfter

    # loan = BZX.getLoan(history[-1].logs[4]['topics'][3])
    loan = BZX.getUserLoans(account, 0, 100, 0, False, False)[0]
    tokenBalanceBefore = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceBefore = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("tokenBalanceBefore: ", tokenBalanceBefore)
    print("collatralTokenBalanceBefore: ", collatralTokenBalanceBefore)
    closeWithDeposit(loan, loanToken, account, isNativeToken, BZX)
    tokenBalanceAfter = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceAfter = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("tokenBalanceAfter: ", tokenBalanceAfter)
    print("collatralTokenBalanceAfter: ", collatralTokenBalanceAfter)
    assert tokenBalanceBefore > tokenBalanceAfter
    assert collatralTokenBalanceBefore < collatralTokenBalanceAfter


def margin_trade(loanToken, itoken, collateral, isNativeToken, isNativeCollateral, account, USDT, interface, BZX):
    if (collateral.allowance(account, itoken) == 0):
        collateral.approve(itoken, 2**256-1, {'from': account})
        
    amount = get_amount(collateral, USDT, interface, BZX)
    acc = accounts.at(account)

    print("itoken: ", itoken.symbol())
    print("token: ", loanToken.symbol())
    print("isNativeToken: ", isNativeToken)
    print("collateral: ", collateral.symbol())
    print("isNativeCollateral: ", isNativeCollateral)
    print("trade amount: ", amount)
    print("account: ", account)

    collatralTokenBalanceBefore = collateral.balanceOf(acc) if not isNativeCollateral else acc.balance()
    print("collatralTokenBalanceBefore: ", collatralTokenBalanceBefore)

    print("MarginTrade ", loanToken.symbol(), " / ", collateral.symbol(), "[", amount, "]")

    print(itoken.marginTrade.encode_input(0x0000000000000000000000000000000000000000000000000000000000000000,3000000000000000000, 0, amount, collateral, account, b''))

    itoken.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000,  3000000000000000000, 0, amount, collateral, account, b'', {'from': acc})
    assert history[-1].status.name == 'Confirmed'
    collatralTokenBalanceAfter = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("collatralTokenBalanceAfter: ", collatralTokenBalanceAfter)
    assert collatralTokenBalanceBefore > collatralTokenBalanceAfter


def test_1(input, TOKENS, ITOKENS, interface, BZX, HELPER):
    tokenName = input[2]
    itokenName = input[1]
    iToken = ITOKENS[input[1]]
    token = TOKENS[input[2]]
    account = holders()[tokenName]
    decimals = interface.IERC20Detailed(token).decimals()
    USDT = TOKENS['USDT']
    amount = get_amount(token, USDT, interface, BZX) * 100
    loanToken = interface.ERC20(iToken.loanTokenAddress()) 

    if(input[0] == 'mint'):
        t_mint(iToken, token, amount, account)
    elif(input[0] == 'borrow'):
        t_borrow(loanToken, iToken, token, account, False, False, USDT, interface, BZX, HELPER)

    elif(input[0] == 'trade'):
        margin_trade(loanToken, iToken, token, False, False, account,  USDT, interface, BZX)
   
    else:
        pass