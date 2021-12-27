BZX = Contract.from_abi("BZX", "0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x5a6f1e81334C63DE0183A4a3864bD5CeC4151c27", TokenRegistry.abi)
SWEEP_FEES = Contract.from_abi("STAKING", "0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", FeeExtractAndDistribute_Polygon.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

CHEF =  Contract.from_abi("CHEF", "0xd39Ff512C3e55373a30E94BB1398651420Ae1D43", MasterChef_Polygon.abi)
PGOV = Contract.from_abi("PGOV", "0xd5d84e75f48E75f01fb2EB6dFD8eA148eE3d0FEb", GovToken.abi)
PGOV_MATIC_LP = Contract.from_abi("PGOV", "0xC698b8a1391F88F497A4EF169cA85b492860b502", interface.ERC20.abi)
HELPER = Contract.from_abi("HELPER", "0xCc0fD6AA1F92e18D103A7294238Fdf558008725a", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
SUSHI_ROUTER = Contract.from_abi("router", "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", interface.IPancakeRouter02.abi)

CONVERTER =  Contract.from_abi("CONVERTER", "0x91c78Bd238AcC14459673d5cf4fE460AeE7BF692", FixedSwapTokenConverter.abi)
MERKLEDISTRIBUITOR = Contract.from_abi("MERKLEDISTRIBUITOR", "0xFA079100e297253a1eb9783aa93646ecF2d5615e", MerkleDistributor.abi)
GUARDIAN_MULTISIG = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
P125 = Contract.from_abi("P125", "0x83000597e8420ad7e9edd410b2883df1b83823cf", P125Token.abi)

