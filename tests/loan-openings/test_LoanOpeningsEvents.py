#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId, setupLoanPool


@pytest.fixture(scope="module")
def LinkDaiBorrowParamsId(Constants, LINK, DAI, bzx, accounts, WETH):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "0",  # torque loan
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]


@pytest.fixture(scope="module")
def LinkDaiTradeParamsId(Constants, LINK, DAI, bzx, accounts, WETH):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "2419200"  # 28 days
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]


@pytest.fixture(scope="module")
def loanId_LINK_DAI(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId)


@pytest.fixture(scope="module")
def setup(Constants, bzx, LINK, DAI, accounts):
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

    loanTokenSent = 1e18
    newPrincipal = 101e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        {"from": accounts[0]}
    )

    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        newPrincipal,
        50e18,
        True
    )
    print("collateralTokenSent", collateralTokenSent)
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        {"from": accounts[0]}
    )
    return collateralTokenSent


def test_borrowOrTradeFromPoolBorrowEvent(Constants, bzx, accounts, LinkDaiBorrowParamsId, DAI, LINK, setup):
    tx = bzx.borrowOrTradeFromPool(
        LinkDaiBorrowParamsId,  # loanParamsId
        "0",  # loanId - starts a new loan
        True,  # isTorqueLoan,
        50e18,  # initialMargin
        [
            accounts[2],  # lender
            accounts[1],  # borrower
            accounts[1],  # receiver
            Constants["ZERO_ADDRESS"],  # manager
        ],
        [
            5e18,  # newRate (5%)
            101e18,  # newPrincipal
            1e18,  # torqueInterest
            1e18,  # loanTokenSent
            setup  # collateralTokenSent
        ],
        b'',  # loanDataBytes
        {"from": accounts[1]}
    )

    tx.info()

    borrowEvent = tx.events["Borrow"][0]
    assert(borrowEvent["user"] == accounts[1])
    assert(borrowEvent["lender"] == accounts[2])
    assert(borrowEvent["loanToken"] == DAI)
    assert(borrowEvent["collateralToken"] == LINK)
    assert(borrowEvent["newPrincipal"] == 101e18)


def test_borrowOrTradeFromPoolTradeEvent(Constants, bzx, accounts, LinkDaiTradeParamsId, DAI, LINK, setup):
    tx = bzx.borrowOrTradeFromPool(
        LinkDaiTradeParamsId,  # loanParamsId
        "0",  # loanId - starts a new loan
        False,  # isTorqueLoan,
        50e18,  # initialMargin
        [
            accounts[2],  # lender
            accounts[1],  # borrower
            accounts[1],  # receiver
            Constants["ZERO_ADDRESS"],  # manager
        ],
        [
            5e18,  # newRate (5%)
            101e18,  # newPrincipal
            0,  # torqueInterest
            1e18,  # loanTokenSent
            setup  # collateralTokenSent
        ],
        b'',  # loanDataBytes
        {"from": accounts[1]}
    )
    tx.info()

    borrowEvent = tx.events["Trade"][0]
    assert(borrowEvent["user"] == accounts[1])
    assert(borrowEvent["lender"] == accounts[2])
    assert(borrowEvent["loanToken"] == DAI)
    assert(borrowEvent["collateralToken"] == LINK)


def test_setDelegatedManagerSetEvent(Constants, bzx, accounts, loanId_LINK_DAI):
    tx = bzx.setDelegatedManager(
        loanId_LINK_DAI, accounts[2], True, {"from": accounts[1]})
    tx.info()
    delegatedManagerSet = tx.events["DelegatedManagerSet"][0]
    assert(delegatedManagerSet["loanId"] == loanId_LINK_DAI)
    assert(delegatedManagerSet["delegator"] == accounts[1])
    assert(delegatedManagerSet["delegated"] == accounts[2])
    assert(delegatedManagerSet["isActive"])


def test_EarnRewardEvent(Constants, bzx, accounts, LinkDaiTradeParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        {"from": accounts[0]}
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        {"from": accounts[0]}
    )

    tx = bzx.borrowOrTradeFromPool(
        LinkDaiTradeParamsId,  # loanParamsId
        "0",  # loanId
        False,  # isTorqueLoan,
        100e18,  # initialMargin
        [
            accounts[2],  # lender
            accounts[1],  # borrower
            accounts[1],  # receiver
            Constants["ZERO_ADDRESS"],  # manager
        ],
        [
            5e18,  # newRate (5%)
            loanTokenSent,  # newPrincipal
            0,  # torqueInterest
            loanTokenSent,  # loanTokenSent
            collateralTokenSent  # collateralTokenSent
        ],
        b'',  # loanDataBytes
        {"from": accounts[1]}
    )
    tradeEvent = tx.events['Trade'][0]
    assert(tradeEvent['user'] == accounts[1])
    assert(tradeEvent['lender'] == accounts[2])
    assert(tradeEvent['collateralToken'] == LINK.address)
    assert(tradeEvent['loanToken'] == DAI.address)

    loanId = tradeEvent['loanId']

    # payTradingFeeEvent = tx.events[0][0]
    # kessak of PayTradinfFee event
    event = filterEvents("0xb23479169712c443e6b00fb0cec3506a5f5926f541df4243d313e11c8c5c71ed", tx.events)
    assert(event['topic1'] ==
           '0xb23479169712c443e6b00fb0cec3506a5f5926f541df4243d313e11c8c5c71ed')
    assert('0X' + event['topic2'][26:66] == accounts[1])
    assert(('0X' + event['topic3']
            [26:66].upper()) == DAI.address.upper())
    assert(event['topic4'] == loanId)


def filterEvents(topic, events):
    for event in events:
        for key in event.keys():
            if key == 'topic1':
                if event[key] == topic:
                    payBorrowingFeeEvent = event
                    break
    return payBorrowingFeeEvent
