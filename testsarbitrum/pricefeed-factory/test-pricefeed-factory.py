from brownie import *
import pytest

@pytest.fixture(scope="module")
def FACTORY(FeedFactory, PRICE_FEEDS, TWAP, QUOTE, accounts):
    f = FeedFactory.deploy(PRICE_FEEDS, TWAP, QUOTE, 2, {"from":accounts[0]})
    f.setSpecs((f, f, f, 0, 30*60), {"from":f.owner()})
    PRICE_FEEDS.setPriceFeed([QUOTE],["0x50834f3163758fcc1df9973b6e91f0f0f0434ad3"], {"from":PRICE_FEEDS.owner()})
    PRICE_FEEDS.setDecimals([QUOTE], {"from":PRICE_FEEDS.owner()})
    PRICE_FEEDS.setPriceFeedFactory(f, {"from":PRICE_FEEDS.owner()})
    return f
@pytest.fixture(scope="module")
def PRICE_FEEDS(PriceFeeds, accounts):
    return PriceFeeds.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def TWAP(Univ3Twap, accounts):
    return Univ3Twap.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def QUOTE():
    return "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"

#deploy factory, add new price feed, query rates/return
def test_case1(FACTORY, QUOTE, interface, accounts, FactoryFeed):
    FACTORY.newPriceFeed("0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a", {"from":accounts[1]})
    returns = interface.IPriceFeeds(FACTORY.PRICE_FEEDS()).queryReturn("0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a", QUOTE, 1e18)
    assert returns > 10e6
    FACTORY.newPriceFeed("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", {"from":accounts[1]})
    returns = interface.IPriceFeeds(FACTORY.PRICE_FEEDS()).queryReturn("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", QUOTE, 1e18)
    assert returns > 500e6