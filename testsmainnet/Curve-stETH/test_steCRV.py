from brownie import *
import pytest

@pytest.fixture(scope="module")
def YVAULT(accounts, PriceFeedyVaultstETH):
    return PriceFeedyVaultstETH.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def curvestETH(accounts, PriceFeedCurvestETH):
    return PriceFeedCurvestETH.deploy({"from":accounts[0]})

@pytest.fixture(scope="module")
def PRICE_FEED(Contract, PriceFeeds):
    return Contract.from_abi("PRICE_FEED","0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d",PriceFeeds.abi)

@pytest.fixture(scope="module")
def yVault(interface):
    return interface.IERC20("0xdCD90C7f6324cfa40d7169ef80b12031770B4325")

@pytest.fixture(scope="module")
def WETH(interface):
    return interface.IERC20("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")

@pytest.fixture(scope="module")
def steCRV(interface):
    return interface.IERC20("0x06325440D014e39736583c165C2963BA99fAf14E")

def test_case(accounts, PRICE_FEED, YVAULT, curvestETH, yVault, steCRV, WETH):
    PRICE_FEED.setPriceFeed([yVault, steCRV], [YVAULT, curvestETH], {"from":PRICE_FEED.owner()})
    price_steCRV = PRICE_FEED.queryReturn(steCRV, WETH, 1e18)
    price_yVault = PRICE_FEED.queryReturn(yVault, WETH, 1e18)
    print(price_steCRV)
    print(price_yVault)
    assert(price_yVault > price_steCRV)
    assert(price_steCRV > 9e17)