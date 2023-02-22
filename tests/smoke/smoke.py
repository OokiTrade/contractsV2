
from brownie import *
import pytest

env = {
    '1': {
        'protocol': '0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f',
        'regestry': '0xf0E474592B455579Fe580D610b846BdBb529C6F7',
        'helper': '0xb887f5b81deec1e271b06257f138e5a9d422bc8c',
        'holders': {
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
        },
        'aliases': {

        }
    },

    '42161': {
        'protocol': '0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB',
        'regestry': '0x86003099131d83944d826F8016E09CC678789A30',
        'helper': '0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21',
        'holders': {
            'USDC': '0x62383739d68dd0f844103db8dfb05a7eded5bbe6',
            #'WETH': '0xc31e54c7a869b9fcbecc14363cf510d1c41fa443',
            'WBTC': '0x149e36e72726e0bcea5c59d40df2c43f60f5a22d'

        },
        'aliases': {
            'iWBTC': 'iBTC'
        }
    }
}

@pytest.fixture(scope="module")
def ENV():
    thisNetwork = network.chain.id
    return env[str(thisNetwork)]

@pytest.fixture(scope="module")
def regestry(TokenRegistry, ENV):
    return Contract.from_abi("TOKEN_regestry", ENV['regestry'], TokenRegistry.abi)


@pytest.fixture(scope="module")
def bzx(interface, ENV):
    return Contract.from_abi("bzx", ENV['protocol'], interface.IBZx.abi)

@pytest.fixture(scope="module")
def HELPER(interface, ENV):
    return Contract.from_abi("HELPER", ENV['helper'], HelperImpl.abi)



@pytest.fixture(scope="module")
def ITOKENS(regestry):
    res = {}
    list = regestry.getTokens(0, 50)
    for l in list:
        iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
        res[iTokenTemp.symbol()] = iTokenTemp
    return res

@pytest.fixture(scope="module")
def TOKENS(regestry):
    res = {}
    list = regestry.getTokens(0, 50)
    for l in list:
        underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
        if (l[1] == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"):
            res["MKR"] = underlyingTemp # MRK has some fun symbol()
        else:
            res[underlyingTemp.symbol()] = underlyingTemp
    return res



def pytest_generate_tests(metafunc):
    res = []
    aliases =  env['42161']['aliases']

    #ToDo: load from ENV fixture!!!!!!
    for i in env['42161']['holders'].keys():
        for j in env['42161']['holders'].keys():
            itokenname = 'i'+i
            if(itokenname in aliases):
                itokenname = aliases[itokenname]

            if(i == j):
                res.append(['mint', itokenname, j])
            else:
                res.append(['borrow', itokenname, j])
                res.append(['trade', itokenname, j])

    print(res)

    metafunc.parametrize("input", res)
    return res



def get_amount(loanToken, USDT, interface, bzx):
    print('==================')
    decimals = interface.IERC20Metadata(loanToken).decimals()
    print(loanToken.symbol())
    print(decimals)
    pricefeeds = interface.IPriceFeeds(bzx.priceFeeds())
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
    itoken.redeem(amount, account, account, {'from': account})
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


def closeWithDeposit(loan, token, account, isNative, bzx):
    if (token.allowance(account, bzx) == 0):
        token.approve(bzx, 2**256-1, {'from': account})
    print("closeWithDeposit")
    amount = (int)(loan[4] * 1.01)
    value = 0 if not isNative else amount
    print("loan before: ", loan)
    print("Value: ", value)
    bzx.closeWithDeposit(loan[0], account, amount, b'', {'from': account, 'value': value})
    assert history[-1].status.name == 'Confirmed'
    print("loan after: ", bzx.getLoan(loan[0]))


def t_borrow(loanToken, itoken, collateral, account, isNativeToken, isNativeCollateral, USDT, interface, bzx, HELPER):
    amount = get_amount(loanToken, USDT, interface, bzx)
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

    # loan = bzx.getLoan(history[-1].logs[4]['topics'][3])
    loan = bzx.getUserLoans(account, 0, 100, 0, False, False)[0]
    tokenBalanceBefore = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceBefore = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("tokenBalanceBefore: ", tokenBalanceBefore)
    print("collatralTokenBalanceBefore: ", collatralTokenBalanceBefore)
    closeWithDeposit(loan, loanToken, account, isNativeToken, bzx)
    tokenBalanceAfter = loanToken.balanceOf(account) if not isNativeToken else account.balance()
    collatralTokenBalanceAfter = collateral.balanceOf(account) if not isNativeCollateral else account.balance()
    print("tokenBalanceAfter: ", tokenBalanceAfter)
    print("collatralTokenBalanceAfter: ", collatralTokenBalanceAfter)
    assert tokenBalanceBefore > tokenBalanceAfter
    assert collatralTokenBalanceBefore < collatralTokenBalanceAfter


def margin_trade(loanToken, itoken, collateral, isNativeToken, isNativeCollateral, account, USDT, interface, bzx):
    if (collateral.allowance(account, itoken) == 0):
        collateral.approve(itoken, 2**256-1, {'from': account})
        
    amount = get_amount(collateral, USDT, interface, bzx)
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


def test_1(input, TOKENS, ITOKENS, interface, bzx, HELPER, ENV):
    tokenName = input[2]
    itokenName = input[1]
    iToken = ITOKENS[itokenName]
    token = TOKENS[input[2]]
    account = ENV['holders'][tokenName]
    decimals = interface.IERC20Metadata(token).decimals()
    USDT = TOKENS['USDT']
    amount = get_amount(token, USDT, interface, bzx) * 100
    loanToken = interface.ERC20(iToken.loanTokenAddress()) 

    if(input[0] == 'mint'):
        t_mint(iToken, token, amount, account)
    elif(input[0] == 'borrow'):
        t_borrow(loanToken, iToken, token, account, False, False, USDT, interface, bzx, HELPER)

    elif(input[0] == 'trade'):
        margin_trade(loanToken, iToken, token, False, False, account,  USDT, interface, bzx)
   
    else:
        pass