from brownie import *

src = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
gas = 220e9
def test_feed():
    AAVEFeed = '0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012'
    iAAVE = '0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1'
    iTokenFeed = PriceFeedIToken.deploy(AAVEFeed,iAAVE,{'from':src,'gas_price':gas})
    underlyingPrice = interface.IPriceFeedsExt(AAVEFeed).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)

    USDCFeed = '0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5'
    iUSDC = '0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15'
    iTokenFeed = PriceFeedIToken.deploy(USDCFeed,iUSDC,{'from':src,'gas_price':gas})
    underlyingPrice = interface.IPriceFeedsExt(USDCFeed).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)

    WBTCFeed = '0xdeb288F737066589598e9214E782fa5A8eD689e8'
    iWBTC = '0x2ffa85f655752fB2aCB210287c60b9ef335f5b6E'
    iTokenFeed = PriceFeedIToken.deploy(WBTCFeed,iWBTC,{'from':src,'gas_price':gas})
    underlyingPrice = interface.IPriceFeedsExt(WBTCFeed).latestAnswer.call()
    iTokenPrice = iTokenFeed.latestAnswer.call()
    print(underlyingPrice)
    print(iTokenPrice)
    assert(underlyingPrice < iTokenPrice)

    assert(False)
