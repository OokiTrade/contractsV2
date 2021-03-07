#!/usr/bin/python3

import pytest
from helpers import setupLoanPool

def test_setPriceFeedContract(Constants, bzx, accounts):
    priceFeedsOldValue = bzx.priceFeeds()

    tx = bzx.setPriceFeedContract(Constants["ONE_ADDRESS"])
    setPriceFeedContract = tx.events["SetPriceFeedContract"]

    assert(setPriceFeedContract["sender"] == accounts[0]) 
    assert(setPriceFeedContract["oldValue"] == priceFeedsOldValue)
    assert(setPriceFeedContract["newValue"] == Constants["ONE_ADDRESS"])

def test_setSwapsImplContract(Constants, bzx, accounts):
    swapsImpl = bzx.swapsImpl()

    tx = bzx.setSwapsImplContract( Constants["ONE_ADDRESS"])
    setPriceFeedContract = tx.events["SetSwapsImplContract"]

    assert(setPriceFeedContract["sender"] == accounts[0]) 
    assert(setPriceFeedContract["oldValue"] == swapsImpl)
    assert(setPriceFeedContract["newValue"] == Constants["ONE_ADDRESS"])

def test_setLoanPool(Constants, bzx, accounts):
    tx = bzx.setLoanPool(
        [
            accounts[6],
            accounts[8]
        ],
        [
            accounts[7],
            accounts[9]
        ]
    )
    setLoanPool = tx.events["SetLoanPool"]
    assert(setLoanPool[0]["sender"] == accounts[0])
    assert(setLoanPool[0]["loanPool"] == accounts[6])
    assert(setLoanPool[0]["underlying"] == accounts[7])

    assert(setLoanPool[1]["sender"] == accounts[0])
    assert(setLoanPool[1]["loanPool"] == accounts[8])
    assert(setLoanPool[1]["underlying"] == accounts[9])

def test_setSupportedTokens(Constants, bzx, DAI, LINK, accounts):
    tx = bzx.setSupportedTokens(
        [
            DAI,
            LINK
        ],
        [
            True,
            False
        ],
        False
    )   
    print("tx.events", tx.events)
    setSupportedTokens = tx.events["SetSupportedTokens"]
    assert(setSupportedTokens[0]["sender"] == accounts[0])
    assert(setSupportedTokens[0]["token"] == DAI)
    assert(setSupportedTokens[0]["isActive"] == True)

    assert(setSupportedTokens[1]["sender"] == accounts[0])
    assert(setSupportedTokens[1]["token"] == LINK)
    assert(setSupportedTokens[1]["isActive"] == False)

def test_setLendingFeePercent(Constants, bzx, accounts):
    newValue = 10**18
    lendingFeePercent = bzx.lendingFeePercent()
    tx = bzx.setLendingFeePercent(newValue)
    setLendingFeePercent = tx.events["SetLendingFeePercent"]

    assert(setLendingFeePercent[0]["sender"] == accounts[0])
    assert(setLendingFeePercent[0]["oldValue"] == lendingFeePercent)
    assert(setLendingFeePercent[0]["newValue"] == newValue)

def test_setTradingFeePercent(Constants, bzx, accounts):
    newValue = 15 * 10**16
    tradingFeePercent = bzx.tradingFeePercent()
    tx = bzx.setTradingFeePercent(newValue)
    setTradingFeePercent = tx.events["SetTradingFeePercent"]

    assert(setTradingFeePercent[0]["sender"] == accounts[0])
    assert(setTradingFeePercent[0]["oldValue"] == tradingFeePercent)
    assert(setTradingFeePercent[0]["newValue"] == newValue)

def test_setBorrowingFeePercent(Constants, bzx, accounts):
    newValue = 8 * 10**16
    borrowingFeePercent = bzx.borrowingFeePercent()
    tx = bzx.setBorrowingFeePercent(newValue)
    setBorrowingFeePercent = tx.events["SetBorrowingFeePercent"]

    assert(setBorrowingFeePercent[0]["sender"] == accounts[0])
    assert(setBorrowingFeePercent[0]["oldValue"] == borrowingFeePercent)
    assert(setBorrowingFeePercent[0]["newValue"] == newValue)

def test_setAffiliateFeePercent(Constants, bzx, accounts):
    newValue = 29 * 10**16
    affiliateFeePercent = bzx.affiliateFeePercent()
    tx = bzx.setAffiliateFeePercent(newValue)
    setAffiliateFeePercent = tx.events["SetAffiliateFeePercent"]

    assert(setAffiliateFeePercent[0]["sender"] == accounts[0])
    assert(setAffiliateFeePercent[0]["oldValue"] == affiliateFeePercent)
    assert(setAffiliateFeePercent[0]["newValue"] == newValue)

def test_setLiquidationIncentivePercent(Constants, bzx, accounts, DAI, WETH):
    newValue = 4 * 10**18
    liquidationIncentivePercent = bzx.liquidationIncentivePercent(DAI, WETH)
    tx = bzx.setLiquidationIncentivePercent([DAI], [WETH], [newValue])
    setLiquidationIncentivePercent = tx.events["SetLiquidationIncentivePercent"]

    assert(setLiquidationIncentivePercent[0]["sender"] == accounts[0])
    assert(setLiquidationIncentivePercent[0]["loanToken"] == DAI)
    assert(setLiquidationIncentivePercent[0]["collateralToken"] == WETH)
    assert(setLiquidationIncentivePercent[0]["oldValue"] == liquidationIncentivePercent)
    assert(setLiquidationIncentivePercent[0]["newValue"] == newValue)

def test_setMaxSwapSize(Constants, bzx, accounts):
    newValue = "100 ether"
    maxSwapSize = bzx.maxSwapSize()
    tx = bzx.setMaxSwapSize(newValue)
    setMaxSwapSize = tx.events["SetMaxSwapSize"]

    assert(setMaxSwapSize[0]["sender"] == accounts[0])
    assert(setMaxSwapSize[0]["oldValue"] == maxSwapSize)
    assert(setMaxSwapSize[0]["newValue"] == newValue)

def test_setFeesController(Constants, bzx, accounts):
    feesController = bzx.feesController()
    tx = bzx.setFeesController(Constants["ONE_ADDRESS"])
    setFeesController = tx.events["SetFeesController"]

    assert(setFeesController[0]["sender"] == accounts[0])
    assert(setFeesController[0]["oldController"] == feesController)
    assert(setFeesController[0]["newController"] == Constants["ONE_ADDRESS"])

 
# WIP
# def queryFees(Constants, bzx, accounts, DAI, LINK, FeesHelper):
#     assert False

# WIP
# def test_withdrawFees(Constants, bzx):
#     assert False

