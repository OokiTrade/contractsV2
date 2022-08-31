from brownie import *

exec(open("./scripts/env/set-matic.py").read())
deployer = accounts[0]

price_feed_old = PRICE_FEED

price_feed_new = PriceFeeds.deploy({"from": deployer})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
tokens = []
feeds = []
for assetPair in supportedTokenAssetsPairs:
    # existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    # print("itoken", existingIToken.symbol(), assetPair[0])
    tokens.append(assetPair[1])
    feeds.append(price_feed_old.pricesFeeds(assetPair[1]))

price_feed_new.setPriceFeed(tokens, feeds, {"from": deployer})
price_feed_new.setDecimals(tokens, {"from": deployer})

price_feed_new.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
price_feed_new.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})


BZX.setPriceFeedContract(price_feed_new, {"from": GUARDIAN_MULTISIG})