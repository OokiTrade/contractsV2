MINIMAL_RATES = {
    "iARB":   0.1e18
}
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9", abi=LoanTokenLogicStandard.abi)
ARB = '0x912ce59144191c1204e64559fe8253a0e49e6548'

# arbPriceFeed = 'TBU' #Chainlink
# PRICE_FEED.setPriceFeed([ARB], [arbPriceFeed], {"from": GUARDIAN_MULTISIG})
# PRICE_FEED.setDecimals([ARB], {"from": GUARDIAN_MULTISIG})

BZX.setApprovals([ARB], [1,2], {'from': GUARDIAN_MULTISIG})

#iARB
iARBProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
#iARBProxy = Contract.from_abi("iARBProxy", address="", abi=LoanToken.abi)
iARB = Contract.from_abi("iARB", iARBProxy, LoanTokenLogicStandard.abi)
underlyingSymbol = "ARB"
iTokenSymbol = "i{}".format(underlyingSymbol)
iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
iARB.initialize(ARB, iTokenName, iTokenSymbol, {'from': deployer})
iARB.initializeDomainSeparator({"from": deployer})
iARB.updateFlashBorrowFeePercent(0.03e18, {"from": deployer})

CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iARB.symbol()), MINIMAL_RATES.get(iARB.symbol())), iARB, {"from": GUARDIAN_MULTISIG})
iARB.setDemandCurve(CUI,{"from": deployer})

iARBProxy.transferOwnership(GUARDIAN_MULTISIG, {'from': deployer})

BZX.setLoanPool([iARB], [ARB], {"from": GUARDIAN_MULTISIG})
BZX.setSupportedTokens([ARB], [True], False, {"from": GUARDIAN_MULTISIG})

exec(open("./scripts/env/set-arbitrum.py").read())


supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
loanTokensArr = []
collateralTokensArr = []
amountsArr = []
params = []
BZX.setupLoanPoolTWAI(iARB, {'from': GUARDIAN_MULTISIG})

for tokenAssetPairA in supportedTokenAssetsPairs:
    params.clear()
    loanTokensArr.clear()
    collateralTokensArr.clear()
    amountsArr.clear()

    # below is to allow new iToken.loanTokenAddress in other existing iTokens
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
    print("itoken", existingIToken.symbol(), tokenAssetPairA[0])

    for tokenAssetPairB in supportedTokenAssetsPairs:
        collateralTokenAddress = tokenAssetPairB[1]
        existingToken = Contract.from_abi("existingToken", address=existingITokenLoanTokenAddress, abi=TestToken.abi)
        collateralToken = Contract.from_abi("collateralToken", address=collateralTokenAddress, abi=TestToken.abi)
        if collateralTokenAddress == existingITokenLoanTokenAddress:
            continue

        if(existingToken.symbol() != 'ARB' and collateralToken.symbol() != 'ARB'):
            continue

        print(existingToken.name(), " <--> ", collateralToken.name())
        loanParam = [BZX.generateLoanParamId(existingToken, collateralToken, True), True, ZERO_ADDRESS, existingToken, collateralToken, 10e18, 7e18, 0]
        BZX.modifyLoanParams([loanParam], {"from": GUARDIAN_MULTISIG})
        loanParam = [BZX.generateLoanParamId(existingToken, collateralToken, False), True, ZERO_ADDRESS, existingToken, collateralToken, 10e18, 7e18, 1]
        BZX.modifyLoanParams([loanParam], {"from": GUARDIAN_MULTISIG})

        loanTokensArr.append(existingITokenLoanTokenAddress)
        collateralTokensArr.append(collateralTokenAddress)
        amountsArr.append(7*10**18)

    if(len(collateralTokensArr) > 0):
        print("setLiquidationIncentivePercent: ", collateralTokensArr)
        BZX.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": GUARDIAN_MULTISIG})


BZX.setSupportedTokens([ARB], [True], True, {"from": GUARDIAN_MULTISIG})

assert False