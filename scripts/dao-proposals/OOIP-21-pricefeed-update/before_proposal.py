from brownie import *

exec(open("./scripts/env/set-eth.py").read())
price_feed = PriceFeeds.deploy({"from": accounts[0]})
tokenList = []
priceFeedList = []
for l in list:
    tokenList.append(l[1])
    priceFeedList.append(PRICE_FEED.pricesFeeds(l[1]))
print(tokenList)
print(priceFeedList)
price_feed.setPriceFeed(tokenList, priceFeedList, {"from": accounts[0]})
price_feed.setDecimals(tokenList, {'from': accounts[0]})

price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": accounts[0]})

itokenImpl = LoanTokenLogicStandard.deploy({"from": accounts[0]});
itokenImplWeth = LoanTokenLogicWeth.deploy({"from": accounts[0]});
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)

    if (iToken == iETH):
        iToken.setTarget(itokenImplWeth,{"from": TIMELOCK})
    else:
        iToken.setTarget(itokenImpl,{"from": TIMELOCK})
    iToken.consume(2**256-1, {"from": TIMELOCK})

tickMathV1 = TickMathV1.at("0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e")
volumeTracker = VolumeTracker.at("0xff00e3da71d76f85dcaf9946a747463c8bfa153f")
liquidationHelper = LiquidationHelper.at("0xcfe69c933a941613f752ab0e255af0ef20cb958b")

lcl= LoanClosingsLiquidation.deploy({"from": accounts[0]})
lc = LoanClosings.deploy({"from": accounts[0]})


BZX.replaceContract(lcl,{"from": TIMELOCK})
BZX.replaceContract(lc,{"from": TIMELOCK})

BZX.setPriceFeedContract(price_feed, {"from": TIMELOCK})
