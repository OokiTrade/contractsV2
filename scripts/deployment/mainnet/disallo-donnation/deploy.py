from brownie import *
exec(open("./scripts/env/set-eth.py").read())
deployer = "0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6"
price_feed = PriceFeeds.at("0xfc1f6b8f47f17ca2d8b5e95ef44874fa5f793123")
# price_feed = PriceFeeds.deploy({"from": deployer})
# tokenList = []
# priceFeedList = []
# for l in list:
#     tokenList.append(l[1])
#     priceFeedList.append(PRICE_FEED.pricesFeeds(l[1]))
# print(tokenList)
# print(priceFeedList)
# price_feed.setPriceFeed(tokenList, priceFeedList, {"from": deployer})
# price_feed.setDecimals(tokenList, {'from': deployer})

itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0x3d01efc7f176a200af301409726fb6ad60fdb0e1", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": deployer})
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xc16f0f6c93fa54d8434cdcef05bfc5611c0ab893", abi=LoanTokenLogicWeth.abi)
# itokenImplWeth = LoanTokenLogicWeth.deploy({"from": deployer})

tickMathV1 = TickMathV1.at("0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e")
# tickMathV1 = TickMathV1.deploy({"from": deployer})
volumeTracker = VolumeTracker.at("0xff00e3da71d76f85dcaf9946a747463c8bfa153f")
# volumeTracker = VolumeTracker.deploy({"from": deployer})
liquidationHelper = LiquidationHelper.at("0xcfe69c933a941613f752ab0e255af0ef20cb958b")
# liquidationHelper = LiquidationHelper.deploy({"from": deployer})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x36bbad70e2979343db70209a528848f5bede00e4", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": deployer})

lc = Contract.from_abi("LoanClosings", address="0x4700c5ffe23ca4d6d50e5d1efb1914b4711b7c33", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": deployer})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

tx_list = []
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if (iToken == iETH):
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
        # iToken.setTarget(itokenImplWeth,{"from": GUARDIAN_MULTISIG})
    else:
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])
        # iToken.setTarget(itokenImpl,{"from": GUARDIAN_MULTISIG})
    tx_list.append([iToken, iToken.consume.encode_input(2**256-1)])
    # iToken.consume(2**256-1, {"from": GUARDIAN_MULTISIG})

tx_list.append([BZX, BZX.replaceContract.encode_input(lcl.address)])
# BZX.replaceContract(lcl,{"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.replaceContract.encode_input(lc.address)])
# BZX.replaceContract(lc,{"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed.address)])
# BZX.setPriceFeedContract(price_feed, {"from": GUARDIAN_MULTISIG})
for tx in tx_list:
    print(tx[0], tx[1])