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


STAKING = Contract.from_abi("STAKING", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingV1_1.abi)

vBZRX = Contract.from_abi("vBZRX", "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", BZRXVestingToken.abi)
POOL3 = Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
BPT = Contract.from_abi("BPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)

SLP = Contract.from_abi("SLP", "0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", TestToken.abi)

HELPER = Contract.from_abi("HELPER", "0x3B55369bfeA51822eb3E85868c299E8127E13c56", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)


stakingProxy = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingProxy.abi)
stakingImpl = StakingV1_1.deploy({'from': stakingProxy.owner()})
stakingProxy.replaceImplementation(stakingImpl, {'from': stakingProxy.owner()})
STAKING = Contract.from_abi("STAKING", stakingProxy.address, StakingV1_1.abi)


SUSHI_ROUTER = Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)

for acc in [accounts[0], accounts[9]]:
    quote = SUSHI_ROUTER.quote(1000*10**18, WETH.address, BZRX.address)
    quote1 = SUSHI_ROUTER.quote(10000*10**18, BZRX.address, WETH.address)
    BZRX.approve(SUSHI_ROUTER, 2**256-1, {'from': acc})
    WETH.approve(SUSHI_ROUTER, 2**256-1, {'from': acc})
    BZRX.transfer(acc, 20000e18, {'from': BZRX})
    WETH.transfer(acc, 20e18, {'from': WETH})
    
    SUSHI_ROUTER.addLiquidity(WETH,BZRX, quote1, BZRX.balanceOf(acc), 0, 0,  acc, 10000000e18, {'from': acc})
    SLP.approve(STAKING, 2**256-1, {'from': acc})
    CHEF =  Contract.from_abi("CHEF", "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd", MasterChef_Polygon.abi)
    SLP.approve(CHEF, 2**256-1, {'from':STAKING})
    SUSHI = Contract.from_abi("SUSHI", "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2", TestToken.abi)

CHEF.deposit(188, SLP.balanceOf(STAKING), {'from': STAKING})

feesExtractorImpl = FeeExtractAndDistribute_ETH.deploy({'from': stakingProxy.owner()})
proxy = Proxy.deploy(feesExtractorImpl, {'from': stakingProxy.owner()})

FEE_EXTRACTOR = Contract.from_abi("FEE_EXTRACTOR", proxy.address, FeeExtractAndDistribute_ETH.abi)
BZX.setFeesController(FEE_EXTRACTOR, {'from': BZX.owner()})



FEE_EXTRACTOR.setPaths([
    ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WETH -> BZRX
    ["0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # WBTC -> WETH -> BZRX
    ["0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # AAVE -> WETH -> BZRX
    # ["0xdd974D5C2e2928deA5F71b9825b8b646686BD200", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    #     "0x56d811088235F11C8920698a204A5010a788f4b3"]  # KNC -> WETH -> BZRX
    ["0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # MKR -> WETH -> BZRX
    ["0x514910771AF9Ca656af840dff83E8264EcF986CA", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # LINK -> WETH -> BZRX
    ["0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # YFI -> WETH -> BZRX
    ["0xc00e94cb662c3520282e6f5717214004a7f26888", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # COMP -> WETH -> BZRX,
    ["0x6b175474e89094c44da98b954eedeac495271d0f", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # LRC -> WETH -> BZRX
    ["0x1f9840a85d5af5bf1d1762f925bdaddc4201f984", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
     "0x56d811088235F11C8920698a204A5010a788f4b3"],  # UNI -> WETH -> BZRX
], {'from': BZX.owner()})

# approve curvpool spent dai
DAI.approve('0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7', 2**256-1, {'from': FEE_EXTRACTOR})
USDC.approve('0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7', 2**256-1, {'from': FEE_EXTRACTOR})
USDT.approve('0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7', 2**256-1, {'from': FEE_EXTRACTOR})
BZRX.approve(STAKING, 2**256-1, {'from': FEE_EXTRACTOR})
POOL3.approve(STAKING, 2**256-1, {'from': FEE_EXTRACTOR})



