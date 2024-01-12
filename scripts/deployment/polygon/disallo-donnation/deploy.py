from brownie import *
exec(open("./scripts/env/set-matic.py").read())
deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6")
price_feed = Contract.from_abi("PriceFeeds", address="0x7FCea20C7136649FeFDE497eb3a207e7f401A4B8", abi=PriceFeeds.abi)
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

itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0x307682D3cBc3F94345b8Ba8F3168fd883D68af5c", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": deployer})
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xaECAD4373Dc7fD95c37cb56446B8DD9dD1394811", abi=LoanTokenLogicWeth.abi)
#itokenImplWeth = LoanTokenLogicWeth.deploy({"from": deployer})

# tickMathV1 = Contract.from_abi("TickMathV1", address="0x6796A1F9682a1Cf4A83D237A57A8F9eBEEC6e4F2", abi=TickMathV1.abi)
tickMathV1 = TickMathV1.at("0x6796A1F9682a1Cf4A83D237A57A8F9eBEEC6e4F2")
# tickMathV1 = TickMathV1.deploy({"from": accounts[0]})
# volumeTracker = Contract.from_abi("VolumeTracker", address="0x184E9c813EcDE3a55CD3E6aD112aF13Bd00EffD6", abi=VolumeTracker.abi)
volumeTracker = VolumeTracker.at("0x184E9c813EcDE3a55CD3E6aD112aF13Bd00EffD6")
# volumeTracker = VolumeTracker.deploy({"from": accounts[0]})
# liquidationHelper = Contract.from_abi("LiquidationHelper", address="0x66Eda677a5E5C48ae0c9a86B1F9Fc1aef2BD8ae6", abi=LiquidationHelper.abi)
liquidationHelper = LiquidationHelper.at("0x66Eda677a5E5C48ae0c9a86B1F9Fc1aef2BD8ae6")
# liquidationHelper = LiquidationHelper.deploy({"from": accounts[0]})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0xd219325Cf1c4FA17E5984feA5911d0Ba0CaE60F9", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": deployer})

lc = Contract.from_abi("LoanClosings", address="0xd3b1b8E5F0e58f87Fe61Ca5EDBfF8767BB194c82", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": accounts[0]})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})
