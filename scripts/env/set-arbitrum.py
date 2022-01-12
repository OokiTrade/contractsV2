BZX = Contract.from_abi("BZX", "0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x86003099131d83944d826F8016E09CC678789A30", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)
DAPP_HELPER = Contract.from_abi("DAPP_HELPER", "0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", DAppHelper.abi)