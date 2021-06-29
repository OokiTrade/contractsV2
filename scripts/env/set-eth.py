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
STAKING = Contract.from_abi("STAKING", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingV1.abi)


vBZRX = Contract.from_abi("vBZRX", "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", BZRXVestingToken.abi)
POOL3 = Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
BPT = Contract.from_abi("BPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)

HELPER = Contract.from_abi("HELPER", "0x3B55369bfeA51822eb3E85868c299E8127E13c56", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)


USDC = Contract.from_abi("USDC", address="0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", abi=interface.ERC20.abi)
swaps = SwapsImplUniswapV2_ETH.deploy({'from':BZX.owner()})
BZX.setSwapsImplContract(swaps, {'from':BZX.owner()})
BZX.replaceContract(swaps, {'from':BZX.owner()})

USDC.approve('0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F', 2**256-1, {'from': BZX.address})
BZX.addStaticRoute(['0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'],{'from':BZX.owner()})