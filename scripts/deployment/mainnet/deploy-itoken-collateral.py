# exec(open("./scripts/deployment/mainnet/deploy_price_feed.py").read())
from gnosis.safe import SafeOperation
from ape_safe import ApeSafe
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[0]
safe = ApeSafe(GUARDIAN_MULTISIG)


# tickMathV1 = accounts[0].deploy(TickMathV1, required_confs=0, gas_price=Wei("12 gwei"), nonce=318) # 0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e
# liquidationHelper = accounts[0].deploy(LiquidationHelper, required_confs=0, gas_price=Wei("12 gwei"), nonce=319) # 0xcfe69c933a941613f752ab0e255af0ef20cb958b
# volumeTracker = accounts[0].deploy(VolumeTracker, required_confs=0, gas_price=Wei("12 gwei"), nonce=320) # 0xff00e3da71d76f85dcaf9946a747463c8bfa153f

# lo = deployer.deploy(LoanOpenings, required_confs=0, gas_price=Wei("12 gwei"), nonce=321) # 0xf426f2609784541653cc351485592e82e57dcb58
# ls = deployer.deploy(LoanSettings, required_confs=0, gas_price=Wei("12 gwei"), nonce=322) # 0xbd4881da92f764e4d7bdd7ef79af0c6585165f64
# ps = deployer.deploy(ProtocolSettings, required_confs=0, gas_price=Wei("12 gwei"), nonce=323) # 0xcec233590474c4d216271bfc0b507cbd40df73ea
# lcs = deployer.deploy(LoanClosingsLiquidation, required_confs=0, gas_price=Wei("12 gwei"), nonce=324) # 0xbcd11e4f7e8a539f9c6fe91dc573ea5bf31aa7f0
# lc = deployer.deploy(LoanClosings, required_confs=0, gas_price=Wei("12 gwei"), nonce=325) # 0xe7121af07d832d49a5a0adf561924c505997181e
# lm = deployer.deploy(LoanMaintenance, required_confs=0, gas_price=Wei("12 gwei"), nonce=326) # 0x91fcdb277e84642ef29db708ff35aa48ba20f04d
# se = deployer.deploy(SwapsExternal, required_confs=0, gas_price=Wei("12 gwei"), nonce=327) # 0xe9aa2a8a7d14fc7ca879fb8aa0e8512231009c14

tickMathV1 = TickMathV1.at("0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e")
liquidationHelper = LiquidationHelper.at("0xcfe69c933a941613f752ab0e255af0ef20cb958b")
volumeTracker = VolumeTracker.at("0xff00e3da71d76f85dcaf9946a747463c8bfa153f")

lo = LoanOpenings.at("0xf426f2609784541653cc351485592e82e57dcb58")
ls = LoanSettings.at("0xbd4881da92f764e4d7bdd7ef79af0c6585165f64")
ps = ProtocolSettings.at("0xcec233590474c4d216271bfc0b507cbd40df73ea")
lcs= LoanClosingsLiquidation.at("0xbcd11e4f7e8a539f9c6fe91dc573ea5bf31aa7f0") # not verified
lc = LoanClosings.at("0xe7121af07d832d49a5a0adf561924c505997181e")
lm = LoanMaintenance.at("0x91fcdb277e84642ef29db708ff35aa48ba20f04d")
se = SwapsExternal.at("0xe9aa2a8a7d14fc7ca879fb8aa0e8512231009c14")

tx_list = []

BZX.replaceContract(lo, {"from": BZX.owner()})
BZX.replaceContract(ls, {"from": BZX.owner()})
BZX.replaceContract(ps, {"from": BZX.owner()})
BZX.replaceContract(lcs, {"from": BZX.owner()})
BZX.replaceContract(lc, {"from": BZX.owner()})
BZX.replaceContract(lm, {"from": BZX.owner()})
BZX.replaceContract(se, {"from": BZX.owner()})

# tx_list.append([BZX, BZX.replaceContract.encode_input(lo)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(ls)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(ps)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(lcs)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(lc)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(lm)])
# tx_list.append([BZX, BZX.replaceContract.encode_input(se)])

# helperImpl = deployer.deploy(HelperImpl, required_confs=0, gas_price=Wei("12 gwei"), nonce=328) # 0x476ebfdb3b00c63eace11cbe699639e737605936
helperImpl = HelperImpl.at("0x476ebfdb3b00c63eace11cbe699639e737605936")

HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
# tx_list.append([HELPER, HELPER.replaceImplementation.encode_input(helperImpl)])
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# itokenImpl = deployer.deploy(LoanTokenLogicStandard, required_confs=0, gas_price=Wei("12 gwei"), nonce=329) # 0x624f7f89414011b276c60ea2337bfba936d1cbbe
# itokenImplWeth = deployer.deploy(LoanTokenLogicWeth, required_confs=0, gas_price=Wei("12 gwei"), nonce=330) # 0x9712dc729916e154daa327c36ad1b9f8e069fba1
itokenImpl = LoanTokenLogicStandard.at("0x624f7f89414011b276c60ea2337bfba936d1cbbe")
itokenImplWeth = LoanTokenLogicWeth.at("0x9712dc729916e154daa327c36ad1b9f8e069fba1")
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    # iBZRX is owned by the guardian
    if (iToken == iBZRX or iToken == iOOKI):
        continue
    if (iToken == iETH):
        iToken.setTarget(itokenImplWeth, {"from": iToken.owner()})
        # tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
    else:
        iToken.setTarget(itokenImpl, {"from": iToken.owner()})
        # tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])

    # tx below will be triggered separately by guardian sig
    # iToken.initializeDomainSeparator({"from": iToken.owner()})
    # BZX.migrateLoanParamsList(l[0], 0, 1000, {"from": BZX.owner()})

    # tx_list.append([iToken, iToken.initializeDomainSeparator.encode_input()])
    # tx_list.append([BZX, BZX.migrateLoanParamsList.encode_input(l[0], 0, 1000)])

price_feed_new = PriceFeeds.at("0x09Ef93750C5F33ab469851F022C1C42056a8BAda")  # not verified
BZX.setPriceFeedContract(price_feed_new, {"from": TIMELOCK})
# tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed_new)])

iTokens = [item[0] for item in TOKEN_REGISTRY.getTokens(0, 100)]
BZX.setSupportedTokens(iTokens, [True] * len(iTokens), True, {'from': TIMELOCK})
tx_list.append([BZX, BZX.setSupportedTokens.encode_input(iTokens, [True] * len(iTokens), True)])

# for tx in tx_list:
#     sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.CALL.value, safe_nonce=safe.pending_nonce())
#     safe.sign_with_frame(sTxn)
#     safe.post_transaction(sTxn)

# small test
USDC.transfer(accounts[0], 100000e6, {"from": "0xf977814e90da44bfa03b6295a0616a897441acec"})
USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})


iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})
