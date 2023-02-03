exec(open("./scripts/env/set_arbitrum.py").read())

deployer = accounts[0]

price_feed_old = PRICE_FEED

BZRX = Deployment_Immutables.BZRX()
WETH = Deployment_Immutables.WETH()
USDC = Deployment_Immutables.USDC()
vBZRX = Deployment_Immutables.VBZRX()
price_feed_new = PriceFeeds.deploy(WETH, USDC, BZRX, vBZRX, OOKI, {"from": deployer})

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

lo = deployer.deploy(LoanOpenings, WETH, USDC, BZRX, vBZRX, OOKI) #
ls = deployer.deploy(LoanSettings, WETH, USDC, BZRX, vBZRX, OOKI) #
ps = deployer.deploy(ProtocolSettings, WETH, USDC, BZRX, vBZRX, OOKI) #
lcs= deployer.deploy(LoanClosingsLiquidation, WETH, USDC, BZRX, vBZRX, OOKI) #
lc = deployer.deploy(LoanClosings, WETH, USDC, BZRX, vBZRX, OOKI) #
lm = deployer.deploy(LoanMaintenance, WETH, USDC, BZRX, vBZRX, OOKI) #
lm2 = deployer.deploy(LoanMaintenance_2, WETH, USDC, BZRX, vBZRX, OOKI) #
se = deployer.deploy(SwapsExternal, WETH, USDC, BZRX, vBZRX, OOKI) #


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



helperImpl = HelperImpl.deploy({"from": accounts[0]}) #
# helperImpl = HelperImpl.at("")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

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

USDC.transfer(accounts[0], 1000000e6, {"from": "0xf977814e90da44bfa03b6295a0616a897441acec"})
USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
USDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
USDC.approve(iETH, 2**256-1, {"from": accounts[0]})
USDC.approve(BZX, 2**256-1, {"from": accounts[0]})
iUSDC.mint(100e6, accounts[0], {"from": accounts[0]})
iUSDT.borrow("", 50e6, 7884000, 100e6, USDC, accounts[0], accounts[0], b"", {'from': accounts[0]})
iUSDT.borrow("", 50e6, 7884000, 100e6, USDC, accounts[0], accounts[0], b"", {'from': accounts[0]})