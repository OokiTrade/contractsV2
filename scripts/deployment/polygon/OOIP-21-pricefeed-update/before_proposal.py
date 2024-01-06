from brownie import *
exec(open("./scripts/env/set-matic.py").read())
price_feed = Contract.from_abi("PriceFeeds", address="0x521A716d34Eb0470Ce62c778Aae1D65843c713f3", abi=PriceFeeds.abi)
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

itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0x075fD79b472bcFe8736Ce5c606848246321C97A4", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": accounts[0]});
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x4ab391CdF2f9B0E57554900A83702cE3D6545FC0", abi=LoanTokenLogicWeth.abi)
#itokenImplWeth = LoanTokenLogicWeth.deploy({"from": accounts[0]});

tickMathV1 = Contract.from_abi("TickMathV1", address="0x6796A1F9682a1Cf4A83D237A57A8F9eBEEC6e4F2", abi=TickMathV1.abi)
# tickMathV1 = TickMathV1.deploy({"from": accounts[0]})
volumeTracker = Contract.from_abi("VolumeTracker", address="0x184E9c813EcDE3a55CD3E6aD112aF13Bd00EffD6", abi=VolumeTracker.abi)
# volumeTracker = VolumeTracker.deploy({"from": accounts[0]})
liquidationHelper = Contract.from_abi("LiquidationHelper", address="0x66Eda677a5E5C48ae0c9a86B1F9Fc1aef2BD8ae6", abi=LiquidationHelper.abi)
# liquidationHelper = LiquidationHelper.deploy({"from": accounts[0]})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x67052b79E6B19EEaB7ABF9670738e7a61f9b9383", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": accounts[0]})

lc = Contract.from_abi("LoanClosings", address="0xd3b1b8E5F0e58f87Fe61Ca5EDBfF8767BB194c82", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": accounts[0]})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": accounts[0]})
