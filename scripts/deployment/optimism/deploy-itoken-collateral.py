# exec(open("./scripts/deployment/bsc/deploy_price_feed.py").read())
exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[0]

tickMathV1 = accounts[0].deploy(TickMathV1)
liquidationHelper = accounts[0].deploy(LiquidationHelper)
volumeTracker = accounts[0].deploy(VolumeTracker)

lo = deployer.deploy(LoanOpenings)
ls = deployer.deploy(LoanSettings)
ps = deployer.deploy(ProtocolSettings)
lcs= deployer.deploy(LoanClosingsLiquidation)
lc = deployer.deploy(LoanClosings)
lm = deployer.deploy(LoanMaintenance)
se = deployer.deploy(SwapsExternal)


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
BZX.replaceContract(se, {"from": BZX.owner()})

helperImpl = HelperImpl.deploy({"from": accounts[0]})
# helperImpl = HelperImpl.at("")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

itokenImpl = deployer.deploy(LoanTokenLogicStandard)
itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
# itokenImpl = LoanTokenLogicStandard.at("")
# itokenImplWeth = LoanTokenLogicWeth.at("")

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})
    iToken.initializeDomainSeparator({"from": iToken.owner()})
    BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})


price_feed_new = PriceFeeds.at("") # not verified
BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})

# small test
USDT.transfer(accounts[0], 100000e6, {"from": "0xf977814e90da44bfa03b6295a0616a897441acec"})
USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.mint(accounts[0], 10000e6, {"from": accounts[0]})

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

iUSDT.approve(iBUSD, 2**256-1, {"from": accounts[0]})
iBUSD.borrow("", 50e6, 0, 100e6, iUSDT, accounts[0], accounts[0], b"", {'from': accounts[0]})