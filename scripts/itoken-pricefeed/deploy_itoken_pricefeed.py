from brownie import *
exec(open("./scripts/env/set-matic.py").read())

iTokens = []
accounts.load('main3')
gas = 20e9
list = TOKEN_REGISTRY.getTokens(0, 50)
for l in list:
    iTokens.append(l[0])

priceFeeds = []
def deploy_eth():
    pricefeeds = []
    for x in iTokens:
        pricefeeds.append(PRICE_FEED.pricesFeeds.call(interface.IToken(x).loanTokenAddress.call()))
    for x in range(0,len(iTokens)):
        contract = PriceFeedIToken.deploy(pricefeeds[x], iTokens[x], {'from':accounts[0], 'gas_price':gas})
        priceFeeds.append(contract.address)
def deploy_poly():
    pricefeeds = []
    for x in iTokens:
        pricefeeds.append(PRICE_FEED.pricesFeeds.call(interface.IToken(x).loanTokenAddress.call()))
    for x in range(0,len(iTokens)):
        contract = PriceFeedIToken.deploy(pricefeeds[x], iTokens[x], {'from':accounts[0], 'gas_price':gas})
        priceFeeds.append(contract.address)
        
def deploy_bsc():
    pricefeeds = []
    for x in iTokens:
        pricefeeds.append(PRICE_FEED.pricesFeeds.call(interface.IToken(x).loanTokenAddress.call()))
    for x in range(0,len(iTokens)):
        contract = PriceFeedIToken.deploy(pricefeeds[x], iTokens[x], {'from':accounts[0], 'gas_price':gas})
        priceFeeds.append(contract.address)

def main():
    deploy_poly()
    print(iTokens)
    print(priceFeeds)
    print(PRICE_FEED.setPriceFeed.encode_input(iTokens,priceFeeds))
