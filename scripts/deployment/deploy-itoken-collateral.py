# exec(open("./scripts/deployment/redeploy-pricefeed.py").read()])
# deployer = accounts[2]
exec(open("./scripts/env/set-arbitrum.py").read())
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
from gnosis.safe import SafeOperation

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

tx_list = []

# BZX.replaceContract(lo, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(lo)])

# BZX.replaceContract(ls, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(ls)])

# BZX.replaceContract(ps, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(ps)])

# BZX.replaceContract(lcs,{"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(lcs)])

# BZX.replaceContract(lc, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(lc)])

# BZX.replaceContract(lm, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(lm)])

# BZX.replaceContract(se, {"from": BZX.owner()})
tx_list.append([BZX, BZX.replaceContract.encode_input(se)])

# helperImpl = HelperImpl.deploy({"from": deployer})
<<<<<<< HEAD
# <HelperImpl Contract '0x3d41a177F3cd7907f8f8fFaeb136428B69C585Eb'>
helperImpl = HelperImpl.at("0x3d41a177F3cd7907f8f8fFaeb136428B69C585Eb")

=======
helperImpl = HelperImpl.at("0x3d41a177F3cd7907f8f8fFaeb136428B69C585Eb")
>>>>>>> 3ef69db62ac184b5b654eeda41ddd5aac0270bdf
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
# HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
tx_list.append([HELPER, HELPER.replaceImplementation.encode_input(helperImpl)])

HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# itokenImpl = deployer.deploy(LoanTokenLogicStandard)
<<<<<<< HEAD
# <LoanTokenLogicStandard Contract '0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9'>
itokenImpl = LoanTokenLogicStandard.at("0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9")

# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
# <LoanTokenLogicWeth Contract '0xaD7d1F1b1F96ba54565075Bd8fC570be9CD99a8F'>
itokenImplWeth = LoanTokenLogicWeth.at("0xaD7d1F1b1F96ba54565075Bd8fC570be9CD99a8F")

=======
# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
itokenImpl = LoanTokenLogicStandard.at("0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9")
itokenImplWeth = LoanTokenLogicWeth.at("0xaD7d1F1b1F96ba54565075Bd8fC570be9CD99a8F")
>>>>>>> 3ef69db62ac184b5b654eeda41ddd5aac0270bdf
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iETH):
        # iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
    else:
        # iToken.setTarget(itokenImpl, {"from": iToken.owner()})
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])

    # iToken.initializeDomainSeparator({"from": iToken.owner()})
    tx_list.append([iToken, iToken.initializeDomainSeparator.encode_input()])

    # BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})
    tx_list.append([BZX, BZX.migrateLoanParamsList.encode_input(l[0], 0, 1000)])


price_feed_new = PriceFeeds.at("0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A")
# BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed_new)])


for tx in tx_list:
    sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.DELEGATE_CALL.value, safe_nonce=safe.pending_nonce())
    safe.sign_with_frame(sTxn)
    safe.post_transaction(sTxn)

# # small test
# USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
# USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
# iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

# iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
# BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})

# iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
# iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})