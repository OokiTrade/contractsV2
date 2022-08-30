from brownie import *

exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts[0]

price_feed_old = PRICE_FEED

price_feed_new = PriceFeeds.deploy({"from": deployer})
# <PriceFeeds Contract '0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A'>
# <PriceFeeds Contract '0xcBC774c564f84eb6F5A388f97a2F447cC6F26791'>
# <PriceFeeds Contract '0xCE0327F4B9B26f0f969F0f2B494Fe4f0E2B2E509'>
price_feed_new = PriceFeeds.at("0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A")

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