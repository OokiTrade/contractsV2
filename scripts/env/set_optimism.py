from brownie import *
BZX = Contract.from_abi("BZX", "0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0x3920993FEca46AF170d296466d8bdb47A4b4e152", HelperImpl.abi)
tickMath = Contract.from_abi("TickMathV1", "0x3D87106A93F56ceE890769A808Af62Abc67ECBD3", TickMathV1.abi)

GUARDIAN_MULTISIG = "0x4e5b10F8221eadCeDEAA84a122620e22775F82Df"
LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x46530E77a3ad47f432D1ad206fB8c44435932B91", LoanTokenSettingsLowerAdmin.abi)
#LOAN_TOKEN_SETTINGS = Contract.from_abi("LOAN_TOKEN_SETTINGS", "0xe98dE80395972Ff6e32885F6a472b38436bE1716", LoanTokenSettings.abi)

MULTICALL3 = Contract.from_abi("MULTICALL3", "0xcA11bde05977b3631167028862bE2a173976CA11", interface.IMulticall3.abi)

DEX_RECORDS = Contract.from_abi("DexRecords", BZX.swapsImpl(), DexRecords.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
SWEEP_FEES = Contract.from_abi("SWEEP_FEES", "0xEfC00F2b226130461f6C9E9C5A5e465BF23FFD77", FeeExtractAndDistribute_Optimism.abi)

CUI = CurvedInterestRate.at("0x100f9EC4E0085d8f469500F66370f8dc64e1F670")
DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(), DexRecords.abi)