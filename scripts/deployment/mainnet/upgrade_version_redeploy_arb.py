exec(open("./scripts/env/set_arbitrum.py").read())

deployer = accounts[0]

price_feed_old = PRICE_FEED

price_feed_new = PriceFeeds.deploy(WETH, {"from": deployer})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
tokens = []
feeds = []
for assetPair in supportedTokenAssetsPairs:
    tokens.append(assetPair[1])
    feeds.append(price_feed_old.pricesFeeds(assetPair[1]))

price_feed_new.setPriceFeed(tokens, feeds, {"from": deployer})
price_feed_new.setDecimals(tokens, {"from": deployer})

price_feed_new.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
price_feed_new.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})


tickMathV1 = accounts[0].deploy(TickMathV1) #
liquidationHelper = accounts[0].deploy(LiquidationHelper) #
volumeTracker = accounts[0].deploy(VolumeTracker) #

lo = deployer.deploy(LoanOpenings) #
ls = deployer.deploy(LoanSettings) #
ps = deployer.deploy(ProtocolSettings) #
lcs= deployer.deploy(LoanClosingsLiquidation) #
lc = deployer.deploy(LoanClosings) #
lm = deployer.deploy(LoanMaintenance) #
lm2 = deployer.deploy(LoanMaintenance_2) #
se = deployer.deploy(SwapsExternal) #


# tickMathV = TickMathV1.at("")
# liquidationHelpe = LiquidationHelper.at("")
# volumeTracke = VolumeTracker.at("")

# lo = LoanOpenings.at("")
# ls = LoanSettings.at("")
# ps = ProtocolSettings.at("")
# lcs= LoanClosingsLiquidation.at("")
# lc = LoanClosings.at("")
# lm = LoanMaintenance.at("")
# se = SwapsExternal.at("")

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(lm2, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

BZX.setPriceFeedContract(price_feed_new, {"from": BZX.owner()})



helperImpl = HelperImpl.deploy(BZX, WETH, {"from": accounts[0]}) #
# helperImpl = HelperImpl.at("")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

ARB_CALLER = "0x01207468F48822f8535BC96D1Cf18EddDE4A2392"
itokenImpl = deployer.deploy(LoanTokenLogicStandard, ARB_CALLER, BZX, WETH) #
itokenImplWeth = deployer.deploy(LoanTokenLogicWeth, ARB_CALLER, BZX, WETH) #
# itokenImpl = LoanTokenLogicStandard.at("")
# itokenImplWeth = LoanTokenLogicWeth.at("")

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})