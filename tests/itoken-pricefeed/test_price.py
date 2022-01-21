from brownie import *

src = '0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199'
gas = 220e9
def test_feed():
    AAVE = '0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9'
    iAAVE = '0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1'
    iTokenFeed = PriceFeedIToken.deploy(AAVE,iAAVE,{'from':src,'gas_price':gas})
    pFeed = PriceFeeds.at('0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d')
    underlyingPrice = interface.IPriceFeedsExt(pFeed.pricesFeeds.call(AAVE)).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)
    USDC = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
    iUSDC = '0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15'
    iTokenFeed = PriceFeedIToken.deploy(USDC,iUSDC,{'from':src,'gas_price':gas})
    pFeed = PriceFeeds.at('0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d')
    underlyingPrice = interface.IPriceFeedsExt(pFeed.pricesFeeds.call(USDC)).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)
    WBTC = '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599'
    iWBTC = '0x2ffa85f655752fB2aCB210287c60b9ef335f5b6E'
    iTokenFeed = PriceFeedIToken.deploy(WBTC,iWBTC,{'from':src,'gas_price':gas})
    pFeed = PriceFeeds.at('0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d')
    underlyingPrice = interface.IPriceFeedsExt(pFeed.pricesFeeds.call(WBTC)).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)
    assert(False)
