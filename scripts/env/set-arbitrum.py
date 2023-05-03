BZX = Contract.from_abi("BZX", "0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x86003099131d83944d826F8016E09CC678789A30", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)
DAPP_HELPER = Contract.from_abi("DAPP_HELPER", "0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", DAppHelper.abi)

GUARDIAN_MULTISIG = "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2"
LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x56f0741f0FF5C3a5f47319F4Ca31E68C482DA38c", LoanTokenSettingsLowerAdmin.abi)

MULTICALL3 = Contract.from_abi("MULTICALL3", "0xcA11bde05977b3631167028862bE2a173976CA11", interface.IMulticall3.abi)

OOKI = Contract.from_abi("OOKI", "0x400F3ff129Bc9C9d239a567EaF5158f1850c65a4", interface.ERC20.abi)
SWEEP_FEES = Contract.from_abi("SWEEP_FEES", "0xcbDE8C5603D4bA855a162A450B1d054A02D8448f", FeeExtractAndDistribute_Arbitrum.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)

CUI = CurvedInterestRate.at("0x138236a9a3BD8A40Ec8e4aF592e6007f352f6beB")

DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(), DexRecords.abi)