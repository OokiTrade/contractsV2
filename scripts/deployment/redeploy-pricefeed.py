exec(open("./scripts/env/set-arbitrum.py").read())


price_feed = PriceFeeds.deploy({"from": accounts[0]})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": accounts[0]})

tokenList = []
priceFeedList = []
for l in list:
    tokenList.append(l[1])
    priceFeedList.append(PRICE_FEED.pricesFeeds(l[1]))
    
price_feed.setPriceFeed(tokenList, priceFeedList, {"from": price_feed.owner()})

BZX.setPriceFeedContract(price_feed, {"from": BZX.owner()})

