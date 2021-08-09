BZX = Contract.from_abi("BZX", "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0xf0E474592B455579Fe580D610b846BdBb529C6F7", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp


    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    if (l[1] == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"):
        globals()["MKR"] = underlyingTemp # MRK has some fun symbol()
    else:
        globals()[underlyingTemp.symbol()] = underlyingTemp

CHI = Contract.from_abi("CHI", "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c", TestToken.abi)


old = Contract.from_abi("STAKING", '0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4', StakingV1.abi)
LPT_OLD = Contract.from_abi("LPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)
LPT_OLD.transfer(accounts[9], 10e18, {'from': '0xe95ebce2b02ee07def5ed6b53289801f7fc137a4'})
LPT_OLD.approve(old, 2**256-1, {'from': accounts[9]})

old.stake([LPT_OLD], [LPT_OLD.balanceOf(accounts[9])], {'from': accounts[9]})


SUSHI_ROUTER = Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)

quote = SUSHI_ROUTER.quote(1000*10**18, WETH.address, BZRX.address)
quote1 = SUSHI_ROUTER.quote(10000*10**18, BZRX.address, WETH.address)
BZRX.approve(SUSHI_ROUTER, 2**256-1, {'from': accounts[9]})
WETH.approve(SUSHI_ROUTER, 2**256-1, {'from': accounts[9]})
BZRX.transfer(accounts[9], 20000e18, {'from': BZRX})
WETH.transfer(accounts[9], 20e18, {'from': WETH})

SUSHI_ROUTER.addLiquidity(WETH,BZRX, quote1, BZRX.balanceOf(accounts[9]), 0, 0,  accounts[9], 10000000e18, {'from': accounts[9]})

STAKING = Contract.from_abi("STAKING", stakingProxy.address, StakingV1_1.abi)

vBZRX = Contract.from_abi("vBZRX", "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", BZRXVestingToken.abi)
POOL3 = Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
BPT = Contract.from_abi("BPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)

HELPER = Contract.from_abi("HELPER", "0x3B55369bfeA51822eb3E85868c299E8127E13c56", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)