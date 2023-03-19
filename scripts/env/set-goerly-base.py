BZX = Contract.from_abi("BZX", "0x5D90e4D6152F3B0dd326df479E0f6DBA2Af57FD5", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0xB73660CC7a358ADffDEb6996deddD561D8EAE36f", TokenRegistry.abi)
ZERO_ADDRESS="0x0000000000000000000000000000000000000000"

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0xc21669005E8a8580E38fa0e06CE24B6634F4F7AC", HelperImpl.abi)

LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x023C20864f5bf97f83dc667cf44fd2ebea972555", LoanTokenSettingsLowerAdmin.abi)

MULTICALL3 = Contract.from_abi("MULTICALL3", "0xcA11bde05977b3631167028862bE2a173976CA11", interface.IMulticall3.abi)

PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)

GUARDIAN_MULTISIG = "0x7C8fE25DD8059a40E2E133fd8A017EFbaEe4fdDd"

CUI = CurvedInterestRate.at("0x3b015a7158E2AD4E7d8557fC1A60ED2002AbdF04")

DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(), DexRecords.abi)

##### fork test
# WETH.transfer(deployer, 3e18, {'from': "0x924ac9910c09a0215b06458653b30471a152022f"})
# accounts[0].transfer(deployer, 50e18)

swapsImplUniswapV2 = Contract.from_abi("router", DEX_RECORDS.dexes(1), SwapsImplUniswapV2_GOERLYBASE.abi)
ROUTER = Contract.from_abi("router", swapsImplUniswapV2.uniswapRouter(), interface.IPancakeRouter02.abi)
FACTORY = Contract.from_abi("FACTORY", ROUTER.factory(), interface.IPancakeFactory.abi)
PAIR = Contract.from_abi("pair", FACTORY.getPair(TUSD, WETH), interface.IPancakePair.abi)
wethPricefeed = interface.IPriceFeedsExt(PRICE_FEED.pricesFeeds(WETH))

# TUSD.approve(ROUTER, 2**256-1, {'from': deployer})
# TUSD.approve(iETH, 2**256-1, {'from': deployer})
# TUSD.approve(iTUSD, 2**256-1, {'from': deployer})
# WETH.approve(iTUSD, 2**256-1, {'from': deployer})
# WETH.approve(iETH, 2**256-1, {'from': deployer})
# iTUSD.mint(deployer, 10000e6, {'from': deployer})
# iETH.mintWithEther(deployer, {'from': deployer, 'value': 1e18})

ROUTER.addLiquidityETH(TUSD, (1e6 * wethPricefeed.latestAnswer()/1e8), 1e6, 1e18,  deployer, chain.time()+100, {'from': deployer, 'value':1e18})
iTUSD.borrow(0x0000000000000000000000000000000000000000000000000000000000000000, 1000000, 7884000, 0.01e18, ZERO_ADDRESS, deployer, deployer, b'', {'from': deployer, 'value':0.01e18})
iETH.borrow(0x0000000000000000000000000000000000000000000000000000000000000000, 1000000, 7884000, 10e6, TUSD, deployer, deployer, b'', {'from': deployer})
iETH.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e6, TUSD, deployer, b'', {'from': deployer})
iTUSD.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 0.01e18, ZERO_ADDRESS, deployer, b'', {'from': deployer, 'value':0.01e18})