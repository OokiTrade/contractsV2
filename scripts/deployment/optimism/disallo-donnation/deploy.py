from brownie import *
exec(open("./scripts/env/set-optimism.py").read())
deployer = accounts[0]
price_feed = Contract.from_abi("PriceFeeds", address="0x61aAf25028C07AEB6c895A9fEB8D695C6D003722", abi=PriceFeeds.abi)
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

itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0xE8dFBeF6a7b2C48BC154C8F57fB4363fe057B1D7", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": deployer})
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x809f126497262078f6aae0Ae4B36aFD67F3f6702", abi=LoanTokenLogicWeth.abi)
# itokenImplWeth = LoanTokenLogicWeth.deploy({"from": deployer})

tickMathV1 = TickMathV1.at("0x8839f57e93B92B251D2Ad1931398B0Ae1c51561D")
# tickMathV1 = TickMathV1.deploy({"from": deployer})
volumeTracker = VolumeTracker.at("0x34bb0E89363C9baf64e9f737ADa646cDE8F47709")
# volumeTracker = VolumeTracker.deploy({"from": deployer})
liquidationHelper = LiquidationHelper.at("0x1b2bf52a094B96B82F42eA162ee6F6852dD7fFc5")
# liquidationHelper = LiquidationHelper.deploy({"from": deployer})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x765e92de3B0dBf8ae616a2B573CE6F71309300E7", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": deployer})

lc = Contract.from_abi("LoanClosings", address="0x3b015a7158E2AD4E7d8557fC1A60ED2002AbdF04", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": deployer})
# price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
# price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

tx_list = []
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if (iToken == iETH):
        # tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
        iToken.setTarget(itokenImplWeth,{"from": GUARDIAN_MULTISIG})
    else:
        # tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])
        iToken.setTarget(itokenImpl,{"from": GUARDIAN_MULTISIG})
    # tx_list.append([iToken, iToken.consume.encode_input(2**256-1)])
    iToken.consume(2**256-1, {"from": GUARDIAN_MULTISIG})

# tx_list.append([BZX, BZX.replaceContract.encode_input(lcl.address)])
BZX.replaceContract(lcl,{"from": GUARDIAN_MULTISIG})
# tx_list.append([BZX, BZX.replaceContract.encode_input(lc.address)])
BZX.replaceContract(lc,{"from": GUARDIAN_MULTISIG})
# tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed.address)])
BZX.setPriceFeedContract(price_feed, {"from": GUARDIAN_MULTISIG})
for tx in tx_list:
    print(tx[0], tx[1])