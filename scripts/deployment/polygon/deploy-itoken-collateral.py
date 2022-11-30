exec(open("./scripts/deployment/polygon/deploy_price_feed.py").read())
deployer = accounts[2]

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

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

helperImpl = HelperImpl.deploy({"from": accounts[0]})
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


# price_feed_new = PriceFeeds.at("0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A")
# BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})

# small test
USDC.transfer(accounts[0], 100000e6, {"from": "0xF977814e90dA44bFA03b6295A0616a897441aceC"})
USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})