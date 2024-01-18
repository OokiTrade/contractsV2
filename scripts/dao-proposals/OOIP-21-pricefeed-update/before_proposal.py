from brownie import *
exec(open("./scripts/env/set-eth.py").read())
price_feed = PriceFeeds.at("0xfc1f6b8f47f17ca2d8b5e95ef44874fa5f793123")
# price_feed = PriceFeeds.deploy({"from": accounts[0]})
# tokenList = []
# priceFeedList = []
# for l in list:
#     tokenList.append(l[1])
#     priceFeedList.append(PRICE_FEED.pricesFeeds(l[1]))
# print(tokenList)
# print(priceFeedList)
# price_feed.setPriceFeed(tokenList, priceFeedList, {"from": accounts[0]})
# price_feed.setDecimals(tokenList, {'from': accounts[0]})
#
# price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
# price_feed.transferOwnership(TIMELOCK, {"from": accounts[0]})

# itokenImpl = LoanTokenLogicStandard.deploy({"from": accounts[0]});
itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0x3d01efc7f176a200af301409726fb6ad60fdb0e1", abi=LoanTokenLogicStandard.abi)
# itokenImplWeth = LoanTokenLogicWeth.deploy({"from": accounts[0]});
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xc16f0f6c93fa54d8434cdcef05bfc5611c0ab893", abi=LoanTokenLogicWeth.abi)

tickMathV1 = TickMathV1.at("0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e")
volumeTracker = VolumeTracker.at("0xff00e3da71d76f85dcaf9946a747463c8bfa153f")
liquidationHelper = LiquidationHelper.at("0xcfe69c933a941613f752ab0e255af0ef20cb958b")

fbh = Contract.from_abi("FlashBorrowFeesHelper", address="0x2A13b2929982B0621c03eFAb90d8C546C644eeb9", abi=FlashBorrowFeesHelper.abi)
# fbh = FlashBorrowFeesHelper.deploy({'from': accounts[0]})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x36bbad70e2979343db70209a528848f5bede00e4", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": accounts[0]})

lc = Contract.from_abi("LoanClosings", address="0x4700c5ffe23ca4d6d50e5d1efb1914b4711b7c33", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": accounts[0]})