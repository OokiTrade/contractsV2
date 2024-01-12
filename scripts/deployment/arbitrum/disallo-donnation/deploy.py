from brownie import *
exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6")
price_feed = Contract.from_abi("PriceFeeds", address="0x144eBb90B7A3099e5403a98E03586a5BAc39b9C2", abi=PriceFeeds.abi)
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

itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0xD3297d69F3A08e85977cc855b16E4192C4190bFa", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": deployer})
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xFb9EA340AE25FF20305d079E5363379F06aCFE4c", abi=LoanTokenLogicWeth.abi)
# itokenImplWeth = LoanTokenLogicWeth.deploy({"from": deployer})

tickMathV1 = TickMathV1.at("0xf68d5d1A35Db485cA5fEAf830bc81c9d3F2DeE0d")
# tickMathV1 = TickMathV1.deploy({"from": deployer})
volumeTracker = VolumeTracker.at("0x65fC5dc47407318362b6Aef1CBCC777646E5b3E5")
# volumeTracker = VolumeTracker.deploy({"from": deployer})
liquidationHelper = LiquidationHelper.at("0x363B3b74cCC01c3ce3C2c63d8BF66ca2BDC2fAE2")
# liquidationHelper = LiquidationHelper.deploy({"from": deployer})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x5dB579823aF0a2998Fb197e950E9403e9E25ee34", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": deployer})

lc = Contract.from_abi("LoanClosings", address="0x8F78e94a4f4c92Ef3832C0158e66779777cD819F", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": deployer})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})
