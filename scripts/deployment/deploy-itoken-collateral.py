exec(open("./scripts/deployment/redeploy-pricefeed.py").read())
deployer = accounts[2]

# tickMathV1 = deployer.deploy(TickMathV1)
# <TickMathV1 Contract '0x210b227Bec2EAb4Fc499Ecfa7347C4Bc969a95d9'>
tickMathV1 = TickMath.at("0x37A3fC76105c51D54a9c1c3167e30601EdeE8782")
# liquidationHelper = deployer.deploy(LiquidationHelper)
# <LiquidationHelper Contract '0x136E7845DC56f31aA80d07C35Cfdc01dAfCCF666'>
liquidationHelper = LiquidationHelper.at("0x136E7845DC56f31aA80d07C35Cfdc01dAfCCF666")
# volumeTracker = deployer.deploy(VolumeTracker)
# <VolumeTracker Contract '0xFd1A56A9c6cD0B5dAef7956Efc131d7A39d4Ab38'>
volumeTracker = VolumeTracker.at("0xFd1A56A9c6cD0B5dAef7956Efc131d7A39d4Ab38")

# lo = deployer.deploy(LoanOpenings)
# <LoanOpenings Contract '0xAC87a33dbeD43ca80b8C1e78A685D9ed6cf78eC5'>
lo = LoanOpenings.at("0xAC87a33dbeD43ca80b8C1e78A685D9ed6cf78eC5")

ls = deployer.deploy(LoanSettings)
ps = deployer.deploy(ProtocolSettings)
lcs= deployer.deploy(LoanClosingsLiquidation)
lc = deployer.deploy(LoanClosings)
lm = deployer.deploy(LoanMaintenance)
se = deployer.deploy(SwapsExternal)

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

helperImpl = HelperImpl.deploy({"from": deployer})
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

itokenImpl = deployer.deploy(LoanTokenLogicStandard)
itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})
    iToken.initializeDomainSeparator({"from": iToken.owner()})
    BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})


price_feed_new = PriceFeeds.at("0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A")
BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})

# small test
USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})