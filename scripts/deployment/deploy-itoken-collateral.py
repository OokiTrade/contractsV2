exec(open("./scripts/deployment/redeploy-pricefeed.py").read())
deployer = accounts[2]

tickMathV1 = accounts[0].deploy(TickMathV1)
liquidationHelper = accounts[0].deploy(LiquidationHelper)

lo = deployer.deploy(LoanOpenings)
ls = deployer.deploy(LoanSettings)
ps = deployer.deploy(ProtocolSettings)
lcs= deployer.deploy(LoanClosingsLiquidation)
lc = deployer.deploy(LoanClosings)
lm = deployer.deploy(LoanMaintenance)

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})

helperImpl = HelperImpl.deploy({"from": accounts[0]})
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

itokenImpl = deployer.deploy(LoanTokenLogicStandard)
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    iToken.setTarget(itokenImpl, {"from": iToken.owner()})
    iToken.initializeDomainSeparator({"from": iToken.owner()})
    BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})


# small test
USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

BZX.setSupportedTokens([iUSDC], [True], True, {'from': GUARDIAN_MULTISIG})

iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})