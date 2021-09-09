BZX = Contract.from_abi("BZX", "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", interface.IBZx.abi)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0xf0E474592B455579Fe580D610b846BdBb529C6F7", TokenRegistry.abi)

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
    globals()[iTokenTemp.symbol()] = iTokenTemp


    underlyingTemp = Contract.from_abi("underlyingTemp", l[1], TestToken.abi)
    if (l[1] == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"):
        globals()["MKR"] = underlyingTemp # MRK has some fun symbol()
    else:
        globals()[underlyingTemp.symbol()] = underlyingTemp

CHI = Contract.from_abi("CHI", "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c", TestToken.abi)


STAKING = Contract.from_abi("STAKING", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingV1_1.abi)

vBZRX = Contract.from_abi("vBZRX", "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", BZRXVestingToken.abi)
POOL3 = Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
BPT = Contract.from_abi("BPT", "0xe26A220a341EAca116bDa64cF9D5638A935ae629", TestToken.abi)

SLP = Contract.from_abi("SLP", "0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", TestToken.abi)

HELPER = Contract.from_abi("HELPER", "0x3B55369bfeA51822eb3E85868c299E8127E13c56", HelperImpl.abi)
PRICE_FEED = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
STAKING = Contract.from_abi("STAKING", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingV1_1.abi)
SUSHI_ROUTER = Contract.from_abi("router", "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", interface.IPancakeRouter02.abi)
SUSHI = Contract.from_abi("SUSHI", "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2", TestToken.abi)

FEE_EXTRACTOR = Contract.from_abi("FEE_EXTRACTOR", BZX.feesController(), FeeExtractAndDistribute_ETH.abi)

DAO = Contract.from_abi("governorBravoDelegator", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)
TIMELOCK = Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi)


CRV = Contract.from_abi("CRV", "0xD533a949740bb3306d119CC777fa900bA034cd52", TestToken.abi)
CRV_MINER  = Contract.from_abi("ICurveMinter", "0xd061D61a4d941c39E5453435B6345Dc261C2fcE0", interface.ICurveMinter.abi)
POOL3Gauge = Contract.from_abi("3POOLGauge", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi)

