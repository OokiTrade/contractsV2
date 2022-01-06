BZX = Contract.from_abi("BZX", "0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x4B234781Af34E9fD756C27a47675cbba19DC8765", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp

    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    globals()[underlyingTemp.symbol()] = underlyingTemp

PGOV = Contract.from_abi("PGOV", "0xd5d84e75f48E75f01fb2EB6dFD8eA148eE3d0FEb", GovToken.abi)
PGOV_MATIC_LP = Contract.from_abi("PGOV", "0xC698b8a1391F88F497A4EF169cA85b492860b502", interface.ERC20.abi)
HELPER = Contract.from_abi("HELPER", "0xdb2800b894FDa88F6c49c38379398b257062dF80", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
SUSHI_ROUTER = Contract.from_abi("router", "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", interface.IPancakeRouter02.abi)

CONVERTER =  Contract.from_abi("CONVERTER", "0x91c78Bd238AcC14459673d5cf4fE460AeE7BF692", FixedSwapTokenConverter.abi)
MERKLEDISTRIBUITOR = Contract.from_abi("MERKLEDISTRIBUITOR", "0xFA079100e297253a1eb9783aa93646ecF2d5615e", MerkleDistributor.abi)
GUARDIAN_MULTISIG = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
P125 = Contract.from_abi("P125", "0x83000597e8420ad7e9edd410b2883df1b83823cf", P125Token.abi)
BZRX_TO_OOKI_CONVERTER = Contract.from_abi("BZRX_TO_OOKI_CONVERTER", "0xc749E8217679817D07f47d1Bb1b651B05c7Cd44F", FixedSwapTokenConverterNotBurn.abi)

