BZX = Contract.from_abi("BZX", "0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x2fA30fB75E08f5533f0CF8EBcbb1445277684E85", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

CHEF = Contract.from_abi("CHEF", "0xd39Ff512C3e55373a30E94BB1398651420Ae1D43", MasterChef_Polygon.abi)
HELPER = Contract.from_abi("HELPER", "0xCc0fD6AA1F92e18D103A7294238Fdf558008725a", HelperImpl.abi)
