# exec(open("./scripts/deployment/bsc/deploy_price_feed.py").read())
exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[0]

# tickMathV1 = accounts[0].deploy(TickMathV1) # 0x292Fa18c5fa55108655aef1297441d7f22E6a048
# liquidationHelper = accounts[0].deploy(LiquidationHelper) # 0xF924981CFD341Fe3f3417f77696e35b68CC6d1Fa
# volumeTracker = accounts[0].deploy(VolumeTracker) # 0xc5De558a1974cF52D2E6ABA3222c56c37a1EDb6F

# lo = deployer.deploy(LoanOpenings) # 0x989b68234cb5d1c7769da27600543F2D481b4cd3
# ls = deployer.deploy(LoanSettings) # 0x564a214E93E72d6f321257C109a9273400D44264
# ps = deployer.deploy(ProtocolSettings) # 0x9005B371aD335E36E5586B8c0f9164606C11Ac00
# lcs= deployer.deploy(LoanClosingsLiquidation) # 0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53 - not verified
# lc = deployer.deploy(LoanClosings) # 0x32AAEA803245cfC01ec4Bb8a70695c94F3c937F9
# lm = deployer.deploy(LoanMaintenance) # 0xe9111F2438eEFA0E3f8C138620A0097D5619E454
# se = deployer.deploy(SwapsExternal) # 0x7613706A9D47a3Ca85185408C4BDA801E308Cd8a


tickMathV = TickMathV1.at("0x292Fa18c5fa55108655aef1297441d7f22E6a048")
liquidationHelpe = LiquidationHelper.at("0xF924981CFD341Fe3f3417f77696e35b68CC6d1Fa")
volumeTracke = VolumeTracker.at("0xc5De558a1974cF52D2E6ABA3222c56c37a1EDb6F")

lo = LoanOpenings.at("0x989b68234cb5d1c7769da27600543F2D481b4cd3")
ls = LoanSettings.at("0x564a214E93E72d6f321257C109a9273400D44264")
ps = ProtocolSettings.at("0x9005B371aD335E36E5586B8c0f9164606C11Ac00")
lcs= LoanClosingsLiquidation.at("0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53")
lc = LoanClosings.at("0x32AAEA803245cfC01ec4Bb8a70695c94F3c937F9")
lm = LoanMaintenance.at("0xe9111F2438eEFA0E3f8C138620A0097D5619E454")
se = SwapsExternal.at("0x7613706A9D47a3Ca85185408C4BDA801E308Cd8a")

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

# helperImpl = HelperImpl.deploy({"from": accounts[0]}) # 0x2aF18586b7A8505626c155EfB22Ad4EDC1504748
helperImpl = HelperImpl.at("0x2aF18586b7A8505626c155EfB22Ad4EDC1504748")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# itokenImpl = deployer.deploy(LoanTokenLogicStandard) # 0x42Ba70e9da5dE545D679bBDB9256Fb47A4E55002
# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth) # 0x61Ed81e9cd5aD65Dff4f7E795028C496029192b1
itokenImpl = LoanTokenLogicStandard.at("0x42Ba70e9da5dE545D679bBDB9256Fb47A4E55002")
itokenImplWeth = LoanTokenLogicWeth.at("0x61Ed81e9cd5aD65Dff4f7E795028C496029192b1")

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})
    iToken.initializeDomainSeparator({"from": iToken.owner()})
    BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})


price_feed_new = PriceFeeds.at("0x7038600CE4E4059436E32DA4a2fc6476fCfD7A2A") # not verified
BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})

# small test
USDT.transfer(accounts[0], 100000e6, {"from": "0xf977814e90da44bfa03b6295a0616a897441acec"})
USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.mint(accounts[0], 10000e6, {"from": accounts[0]})

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

iUSDT.approve(iBUSD, 2**256-1, {"from": accounts[0]})
iBUSD.borrow("", 50e6, 0, 100e6, iUSDT, accounts[0], accounts[0], b"", {'from': accounts[0]})