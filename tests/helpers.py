#!/usr/bin/python3


def setupLoanPool(Constants, bzx, pool, asset):

    underlying = bzx.loanPoolToUnderlying(pool)
    if underlying != asset:
        if underlying != Constants["ZERO_ADDRESS"]:
            bzx.setLoanPool(
                [
                    pool,
                ],
                [
                    Constants["ZERO_ADDRESS"]
                ]
            )

        bzx.setLoanPool(
            [
                pool,
            ],
            [
                asset
            ]
        )

def getLoanId(Constants, bzx, DAI, LINK, accounts, web3, borrowParamsId):
    ## setup simulated loan pool
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

    bZxBeforeDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxBeforeDAIBalance", bZxBeforeDAIBalance)

    bZxBeforeLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxBeforeLINKBalance", bZxBeforeLINKBalance)

    ## loanTokenSent to protocol is just the borrowed/escrowed interest since the actual borrow would have 
    ## already been transfered to the borrower by the pool before borrowOrTradeFromPool is called
    loanTokenSent = 1e18
    newPrincipal = 101e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )

    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        newPrincipal,
        50e18,
        True
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    print("newPrincipal",newPrincipal)
    print("loanTokenSent",loanTokenSent)
    print("collateralTokenSent",collateralTokenSent)

    tx = bzx.borrowOrTradeFromPool(
        borrowParamsId, #loanParamsId
        "0", # loanId - starts a new loan
        True, # isTorqueLoan,
        50e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            newPrincipal, # newPrincipal
            1e18, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    print(tx.info())

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)

    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    borrowEvent = tx.events["Borrow"][0]
    print("borrowEvent", borrowEvent)
    print("borrowEvent.loanId", borrowEvent["loanId"])
    return borrowEvent["loanId"]
