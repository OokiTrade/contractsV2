# exec(open("./scripts/deployment/polygon/deploy_price_feed.py").read())
exec(open("./scripts/env/set-matic.py").read())
# deployer = accounts[0]
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
from gnosis.safe import SafeOperation
# tickMathV1 = accounts[0].deploy(TickMathV1) # 0x1d303522C0A40d204b50a34Ed8885c6E589351E0
# liquidationHelper = accounts[0].deploy(LiquidationHelper) # 0x952D0CB122089fC3ecadd9beC18eCc5a623c21DF
# volumeTracker = accounts[0].deploy(VolumeTracker) # 0xCa0C9628C2bFa8d293D9fA5874f86B23d6eBD7bF

lo = deployer.deploy(LoanOpenings)
ls = deployer.deploy(LoanSettings)
ps = deployer.deploy(ProtocolSettings)
lcs= deployer.deploy(LoanClosingsLiquidation)
lc = deployer.deploy(LoanClosings)
lm = deployer.deploy(LoanMaintenance)
se = deployer.deploy(SwapsExternal)

tx_list = []

# BZX.replaceContract(lo, {"from": BZX.owner()})
# BZX.replaceContract(ls, {"from": BZX.owner()})
# BZX.replaceContract(ps, {"from": BZX.owner()})
# BZX.replaceContract(lcs,{"from": BZX.owner()})
# BZX.replaceContract(lc, {"from": BZX.owner()})
# BZX.replaceContract(lm, {"from": BZX.owner()})
# BZX.replaceContract(se, {"from": BZX.owner()})

tx_list.append([BZX, BZX.replaceContract.encode_input(lo)])
tx_list.append([BZX, BZX.replaceContract.encode_input(ls)])
tx_list.append([BZX, BZX.replaceContract.encode_input(ps)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lcs)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lc)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lm)])
tx_list.append([BZX, BZX.replaceContract.encode_input(se)])

helperImpl = HelperImpl.deploy({"from": accounts[0]})
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
# HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
tx_list.append([HELPER, HELPER.replaceImplementation.encode_input(helperImpl)])
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

itokenImpl = deployer.deploy(LoanTokenLogicStandard)
itokenImplWeth = deployer.deploy(LoanTokenLogicWeth)
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if(iToken == iMATIC):
        # iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
    else:
        # iToken.setTarget(itokenImpl, {"from": iToken.owner()})
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])

    # iToken.initializeDomainSeparator({"from": iToken.owner()})
    # BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})

    tx_list.append([iToken, iToken.initializeDomainSeparator.encode_input()])
    tx_list.append([BZX, BZX.migrateLoanParamsList.encode_input(l[0], 0, 1000)])

price_feed_new = PriceFeeds.at("0xDB0f02A68e5b52A853d01c5e1d935645FF5c01D4") # not verified
# BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed_new)])

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
#BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.setSupportedTokens.encode_input(iTokens, [True] * len(iTokens), True)])

for tx in tx_list:
    sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.CALL.value, safe_nonce=safe.pending_nonce())
    safe.sign_with_frame(sTxn)
    safe.post_transaction(sTxn)

# # small test
# USDC.transfer(accounts[0], 100000e6, {"from": "0x0d0707963952f2fba59dd06f2b425ace40b492fe"})
# USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
# iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})



# iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
# iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})