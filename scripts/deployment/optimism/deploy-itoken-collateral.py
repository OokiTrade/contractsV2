# exec(open("./scripts/deployment/bsc/deploy_price_feed.py").read())
exec(open("./scripts/env/set-optimism.py").read())
# deployer = accounts[0]

# tickMathV1 = accounts[0].deploy(TickMathV1)
# liquidationHelper = accounts[0].deploy(LiquidationHelper)
# volumeTracker = accounts[0].deploy(VolumeTracker)

# lo = deployer.deploy(LoanOpenings)
# ls = deployer.deploy(LoanSettings)
# ps = deployer.deploy(ProtocolSettings)
# lcs= deployer.deploy(LoanClosingsLiquidation)
# lc = deployer.deploy(LoanClosings)
# lm = deployer.deploy(LoanMaintenance)
# se = deployer.deploy(SwapsExternal)


tickMathV1 = TickMathV1.at("0x49743dA77Ff019424E2e153A0712eD87fFDB74Eb")
liquidationHelpe = LiquidationHelper.at("0xeCb076B674d585521087B3162A4F2bc76534Ac54")
volumeTracke = VolumeTracker.at("0x0DAE2558B8438c5089112F730aa319a2727E9912")

lo = LoanOpenings.at("0x1CFE42F0a4ff79CCbC131E6EBDFab01D376D00c3")
ls = LoanSettings.at("0x831dFCa1fB4C35bB68F4B5D94Ce81a2072E2dFEe")
ps = ProtocolSettings.at("0xf7Eb8B08C8860d494D8d8FB6529C46Df599987BB")
lcs= LoanClosingsLiquidation.at("0xE42f4147Ce8bf8D436554feE950ef11DBCeB90f7") # not verified
lc = LoanClosings.at("0x174AFF1bE8da9710A1eC59c1c1b73c9bF6c60b8e")
lm = LoanMaintenance.at("0x7FcB75eaB54D5cEA49cC026Ae7A36ec8F56d7616")
se = SwapsExternal.at("0x4A3A06D264e6F3B67e0BAae96F2457d3C4e3Fadd")

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

# helperImpl = HelperImpl.deploy({"from": accounts[0]})
helperImpl = HelperImpl.at("0xd076bEc0c440780D63A9Ad5B1C3BBB890196Edec")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# itokenImpl = deployer.deploy(LoanTokenLogicStandard)
# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
itokenImpl = LoanTokenLogicStandard.at("0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1")
itokenImplWeth = LoanTokenLogicWeth.at("0x8C085F8f5a5650D282BAce3A134dC22a67Cf411B")

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})
    iToken.initializeDomainSeparator({"from": iToken.owner()})
    BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})


price_feed_new = PriceFeeds.at("0x37A3fC76105c51D54a9c1c3167e30601EdeE8782") # not verified
BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})
iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})


# small test
USDT.transfer(accounts[0], 100000e6, {"from": "0x0d0707963952f2fba59dd06f2b425ace40b492fe"})
USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.mint(accounts[0], 10000e6, {"from": accounts[0]})



iUSDT.approve(iUSDC, 2**256-1, {"from": accounts[0]})
iUSDC.borrow("", 50e6, 0, 100e6, iUSDT, accounts[0], accounts[0], b"", {'from': accounts[0]})