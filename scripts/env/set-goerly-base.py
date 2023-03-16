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