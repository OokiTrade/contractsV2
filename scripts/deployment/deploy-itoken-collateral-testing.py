# exec(open("./scripts/deployment/redeploy-pricefeed.py").read()])
# deployer = accounts[2]
exec(open("./scripts/env/set-arbitrum.py").read())

# tickMathV1 = deployer.deploy(TickMathV1)
# <TickMathV1 Contract '0x210b227Bec2EAb4Fc499Ecfa7347C4Bc969a95d9'>
tickMathV1 = TickMathV1.at("0x210b227Bec2EAb4Fc499Ecfa7347C4Bc969a95d9")
# liquidationHelper = deployer.deploy(LiquidationHelper)
# <LiquidationHelper Contract '0x136E7845DC56f31aA80d07C35Cfdc01dAfCCF666'>
liquidationHelper = LiquidationHelper.at("0x136E7845DC56f31aA80d07C35Cfdc01dAfCCF666")
# volumeTracker = deployer.deploy(VolumeTracker)
# <VolumeTracker Contract '0xFd1A56A9c6cD0B5dAef7956Efc131d7A39d4Ab38'>
volumeTracker = VolumeTracker.at("0xFd1A56A9c6cD0B5dAef7956Efc131d7A39d4Ab38")

# lo = deployer.deploy(LoanOpenings)
# <LoanOpenings Contract '0xAC87a33dbeD43ca80b8C1e78A685D9ed6cf78eC5'>
lo = LoanOpenings.at("0xAC87a33dbeD43ca80b8C1e78A685D9ed6cf78eC5")

# ls = deployer.deploy(LoanSettings)
ls = LoanSettings.at("0x4E0F7FC02A59E2Da46BCBaD2b2Ea19651CbF19ce")

# ps = deployer.deploy(ProtocolSettings)
ps = ProtocolSettings.at("0x713A1CCF3cD3b85d4C9eB57b8fa68FD37dd99e72")

# lcs= deployer.deploy(LoanClosingsLiquidation)
lcs = LoanClosingsLiquidation.at("0x38513c5DC59eAa698D36a6d1123EdC9fFFb4C407")

# lc = deployer.deploy(LoanClosings)
lc = LoanClosings.at("0x548bbdf30F7E6532c9cc6dFD11a47eF7ffC04dd4")

# lm = deployer.deploy(LoanMaintenance)
lm = LoanMaintenance.at("0xAEB27C726178b2C9582a883f3D075944dD9A1D76")

# se = deployer.deploy(SwapsExternal)
se = SwapsExternal.at("0x6D4AEE550C6EBfaed8b5498FbAE28F404E490B58")


BZX.replaceContract(lo, {"from": BZX.owner()})

BZX.replaceContract(ls, {"from": BZX.owner()})

BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs,{"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

# helperImpl = HelperImpl.deploy({"from": deployer})
helperImpl = HelperImpl.at("0x3d41a177F3cd7907f8f8fFaeb136428B69C585Eb")
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})

HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# itokenImpl = deployer.deploy(LoanTokenLogicStandard)
# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
itokenImpl = LoanTokenLogicStandard.at("0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9")
itokenImplWeth = LoanTokenLogicWeth.at("0xaD7d1F1b1F96ba54565075Bd8fC570be9CD99a8F")
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


# # small test
# USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
# USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
# iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

# iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
# iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})