BZX = Contract.from_abi("BZX", "0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x2767078d232f50A943d0BA2dF0B56690afDBB287", TokenRegistry.abi)
ZERO_ADDRESS="0x0000000000000000000000000000000000000000"

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0xF93118c86370A9bd722F6D6E8Df9ebE05e5e854B", HelperImpl.abi)

LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x14E62422eA87349e999a8bcbFB9aD107D1BcDf52", LoanTokenSettingsLowerAdmin.abi)

MULTICALL3 = Contract.from_abi("MULTICALL3", "0xcA11bde05977b3631167028862bE2a173976CA11", interface.IMulticall3.abi)

PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)

GUARDIAN_MULTISIG = "0x7C8fE25DD8059a40E2E133fd8A017EFbaEe4fdDd"

CUI = CurvedInterestRate.at("0xE60d6142D3d683a58B02337E1F0D08C69B946aCF")

DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(), DexRecords.abi)

##### fork
USDC.transfer(deployer, 100000e6, {'from': "0xea02dcc6fe3ec1f2a433ff8718677556a3bb3618"})
WETH.transfer(deployer, 3e18, {'from': "0x924ac9910c09a0215b06458653b30471a152022f"})
accounts[0].transfer(deployer, 50e18)

ROUTER = Contract.from_abi("router", '0xed7899C74D5201Fd6a273a3B69C398DB8Cc1998D', interface.IPancakeRouter02.abi)
FACTORY = Contract.from_abi("FACTORY", ROUTER.factory(), interface.IPancakeFactory.abi)
PAIR = Contract.from_abi("pair", FACTORY.getPair(USDC, WETH), interface.IPancakePair.abi)
wethPricefeed = interface.IPriceFeedsExt(PRICE_FEED.pricesFeeds(WETH))
BZX.setApprovals([USDC, WETH], [1], {'from': deployer})

USDC.approve(ROUTER, 2**256-1, {'from': deployer})
USDC.approve(iETH, 2**256-1, {'from': deployer})
USDC.approve(iUSDC, 2**256-1, {'from': deployer})
WETH.approve(iUSDC, 2**256-1, {'from': deployer})
WETH.approve(iETH, 2**256-1, {'from': deployer})
iUSDC.mint(deployer, 10000e6, {'from': deployer})
ROUTER.addLiquidityETH(USDC, 6e6 * (wethPricefeed.latestAnswer()/1e8), 1e6, 6e18,  deployer, chain.time()+100, {'from': deployer, 'value':6e18})
iETH.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e6, USDC, deployer, b'', {'from': deployer})
iETH.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 10e6, USDC, deployer, b'', {'from': deployer})