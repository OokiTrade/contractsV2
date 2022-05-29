BZX = Contract.from_abi("BZX", "0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x2767078d232f50A943d0BA2dF0B56690afDBB287", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    print("Load: ", iTokenTemp.symbol())
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    print("Load: ", underlyingTemp.symbol())
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0xe98dE80395972Ff6e32885F6a472b38436bE1716", HelperImpl.abi)

LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x4416883645E26EB91D62EB1B9968f925d8388C44", LoanTokenSettingsLowerAdmin.abi)
LOAN_TOKEN_SETTINGS = Contract.from_abi("LOAN_TOKEN_SETTINGS", "0xF082901C5d59846fbFC699FBB87c6D0f538f099d", LoanTokenSettings.abi)
WEVMOS="0xD4949664cD82660AaE99bEdc034a0deA8A0bd517"

EVMOS_PRICEFEED = Contract.from_abi("evmosPricefeed", "0xA87334Eb2Fb7878Dd1Dfdc643670528041b5A7fd", OOKIPriceFeed.abi)