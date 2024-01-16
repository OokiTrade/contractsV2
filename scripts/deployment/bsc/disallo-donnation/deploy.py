from brownie import *
exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[0]
price_feed = Contract.from_abi("PriceFeeds", address="0x80faA8e034229CF2Cf66036a0e55bc379A62e1ef", abi=PriceFeeds.abi)
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


itokenImpl = Contract.from_abi("LoanTokenLogicStandard", address="0xFB3Cf398624b465d54eb11Eef675f74a53671fb4", abi=LoanTokenLogicStandard.abi)
# itokenImpl = LoanTokenLogicStandard.deploy({"from": deployer})
itokenImplWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xc8a86a313C9754C149e2426637E674F8fFbB9348", abi=LoanTokenLogicWeth.abi)
# itokenImplWeth = LoanTokenLogicWeth.deploy({"from": deployer})
assert False

tickMathV1 = TickMathV1.at("0xE3c1A9638855ACBe2D2a9f01706d10e9Bc07173b")
# tickMathV1 = TickMathV1.deploy({"from": deployer})
volumeTracker = VolumeTracker.at("0x316c1DC88aC4dC29F40Bf6AfD0E13eb62F0B9432")
# volumeTracker = VolumeTracker.deploy({"from": deployer})
liquidationHelper = LiquidationHelper.at("0xd4b0014631cE1E2381032AeF5A4821cDFF4067D7")
# liquidationHelper = LiquidationHelper.deploy({"from": deployer})

lcl = Contract.from_abi("LoanClosingsLiquidation", address="0x4a474820AE244E51855156ee6F193d317AF7806e", abi=LoanClosingsLiquidation.abi) #Unverifyed
# lcl= LoanClosingsLiquidation.deploy({"from": deployer})

lc = Contract.from_abi("LoanClosings", address="0x73422B8677E0Fe5595A4069143f646623b9E38Cb", abi=LoanClosings.abi)
# lc = LoanClosings.deploy({"from": deployer})
# price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
# price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

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