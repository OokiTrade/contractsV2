BZX = Contract.from_abi("BZX", "0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], interface.IToken.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0x81B91c9a68b94F88f3DFC4F375f101223dDd5007", HelperImpl.abi)
BGOV = Contract.from_abi("PGOV", "0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF", GovToken.abi)

ADMIN_LOCK = Contract.from_abi("ADMIN_LOCK", "0xcd5788e81821500cc306378e079b34b964876e55", AdminLock.abi)
SUSHI_ROUTER = Contract.from_abi("router", "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", interface.IPancakeRouter02.abi)

GUARDIAN_MULTISIG = "0x82cedB275BF513447300f670708915F99f085FD6"
LOAN_TOKEN_SETTINGS_LOWER_ADMIN = Contract.from_abi("LOAN_TOKEN_SETTINGS_LOWER_ADMIN", "0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", LoanTokenSettingsLowerAdmin.abi)

MULTICALL3 = Contract.from_abi("MULTICALL3", "0xcA11bde05977b3631167028862bE2a173976CA11", interface.IMulticall3.abi)
SWEEP_FEES = Contract.from_abi("SWEEP_FEES", "0xC9726942C732fa048dC56f0DeBea7fB2c596bA8C", FeeExtractAndDistribute_Arbitrum.abi)
OOKI = Contract.from_abi("OOKI", "0xa5a6817ac4c164F27df3254B71fE83904B1C3c3e", interface.ERC20.abi)