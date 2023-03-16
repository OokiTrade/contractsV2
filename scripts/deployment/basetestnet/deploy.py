#bZxProtocol.deploy({'from': deployer})
BZX = Contract.from_abi("BZX", "0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", interface.IBZx.abi)
#TokenRegistry.deploy({'from': deployer})
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x2767078d232f50A943d0BA2dF0B56690afDBB287", TokenRegistry.abi)
ZERO_ADDRESS="0x0000000000000000000000000000000000000000"

#TickMathV1.deploy({'from': deployer})
tickMath = TickMathV1.at("0x9f46635839F9b5268B1F2d17dE290663aBe0C976")
#VolumeTracker.deploy({'from': deployer})
volumeTracker = VolumeTracker.at("0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334")
#LiquidationHelper.deploy({'from': deployer})
liquidationHelper = LiquidationHelper.at("0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1")

#HelperImpl.deploy({"from": deployer})
#helperImpl = HelperImpl.at("0xa3AfC9162952A37b2fd63e90aBF5299D6926d612")
#HelperProxy.deploy(helperImpl, {"from": deployer})
HELPER = Contract.from_abi("HELPER", "0xF93118c86370A9bd722F6D6E8Df9ebE05e5e854B", HelperImpl.abi)

#Receiver.deploy({"from": deployer})
receiver = Contract.from_abi("Receiver", "0x650980C7CB878629Bda2C33828A8F729B9B8635c", Receiver.abi)

## LoanSettings
#LoanSettings.deploy({'from': deployer})
settingsImpl = Contract.from_abi("settingsImpl", address="0x33C334E820E371F1a2A8337FFAae1d289A96f464", abi=LoanSettings.abi)

## LoanOpenings
#LoanOpenings.deploy({'from': deployer})
openingsImpl = Contract.from_abi("openingsImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanOpenings.abi)

## LoanMaintenance
#LoanMaintenance_2.deploy({'from': deployer})
maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=LoanMaintenance_2.abi)

## LoanMaintenance
#maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=LoanMaintenance.abi)

## LoanClosings
#LoanClosings.deploy({'from': deployer})
closingImpl = Contract.from_abi("closingImpl", address="0x3D87106A93F56ceE890769A808Af62Abc67ECBD3", abi=LoanClosings.abi)

## SwapsExternal
#SwapsExternal.deploy({'from': deployer})
swapsImpl = Contract.from_abi("swapsImpl", address="0xE4Ac87b95FFb28FDCb009009b4eDF949702f1785", abi=SwapsExternal.abi)

#PriceFeeds.deploy({"from": deployer})
pricefeeds = Contract.from_abi('priceFeeds', "0x1Ab4bc72BC67EE63c2EA2548798786E330Ae1A31", PriceFeeds.abi)

## ProtocolSettings
#ProtocolSettings.deploy({'from': deployer})
protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xe6fa8A2975B531b668b2500742e97Aa5F395FF7F", abi=ProtocolSettings.abi)

# BZX.replaceContract(protocolsettingsImpl.address, {'from': deployer})
# BZX.replaceContract(settingsImpl.address, {'from': deployer})
# BZX.replaceContract(openingsImpl.address, {'from': deployer})
# BZX.replaceContract(maintenace2Impl.address, {'from': deployer})
# BZX.replaceContract(maintenaceImpl.address, {'from': deployer})
# BZX.replaceContract(closingImpl.address, {'from': deployer})
# BZX.replaceContract(swapsImpl.address, {'from': deployer})
# BZX.setPriceFeedContract(pricefeeds.address, {'from': deployer})


#CurvedInterestRate.deploy({'from':deployer})
CUI = Contract.from_abi("CurvedInterestRate", address="0xE60d6142D3d683a58B02337E1F0D08C69B946aCF", abi=CurvedInterestRate.abi)

#ArbitraryCaller.deploy({'from': deployer})
#LoanTokenSettingsLowerAdmin.deploy({'from': deployer})
settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x14E62422eA87349e999a8bcbFB9aD107D1BcDf52", abi=LoanTokenSettingsLowerAdmin.abi)

#LoanTokenLogicStandard.deploy({'from': deployer})
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x3920993FEca46AF170d296466d8bdb47A4b4e152", abi=LoanTokenLogicStandard.abi)

#LoanTokenLogicWeth.deploy({'from': deployer})
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x6658d93F878Ad0dBc51497939486269968C60Bd6", abi=LoanTokenLogicWeth.abi)


#DexRecords.deploy({'from':deployer})
dex_record = Contract.from_abi("dex_record", address="0xBFcf8755Ba9d23F7F0EBbA0da70819A907dA2aCC", abi=DexRecords.abi)
#SwapsImplUniswapV2_GOERLYBASE.deploy({'from':deployer})
univ2 = Contract.from_abi("SwapsImplUniswapV2_GOERLYBASE", address="0x0515fDe94bb95d6A5b7640f8F0d3AC98C9390903", abi=SwapsImplUniswapV2_GOERLYBASE.abi)
#dex_record.setDexID(univ2.address, {'from':deployer})
#BZX.setSwapsImplContract(dex_record, {'from': deployer})

#BZX.setTWAISettings(60,10800, {'from':BZX.owner()})


WETH = '0x4200000000000000000000000000000000000006'
USDC = '0x2e668Bb88287675e34c8dF82686dfd0b7F0c0383'
ethPriceFeed = '0xcD2A119bD1F7DF95d706DE6F2057fDD45A0503E2' #Chainlink
usdcPriceFeed = '0xb85765935B4d9Ab6f841c9a00690Da5F34368bc0' #Chainlink
# pricefeeds.setPriceFeed([WETH], [ethPriceFeed], {"from": deployer})
# pricefeeds.setPriceFeed([USDC], [usdcPriceFeed], {"from": deployer})


#iUSDC
#LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
iUSDCProxy = Contract.from_abi("iUSDCProxy", address="0x723bD1672b4bafF0B8132eAfc082EB864cF18D24", abi=LoanToken.abi)
iUSDC = Contract.from_abi("iUSDC", iUSDCProxy, LoanTokenLogicStandard.abi)
# underlyingSymbol = "USDC"
# iTokenSymbol = "i{}".format(underlyingSymbol)
# iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
# iUSDC.initialize(USDC, iTokenName, iTokenSymbol, {'from': deployer})
#iUSDC.initializeDomainSeparator({"from": deployer})

#iETH
#LoanToken.deploy(deployer, loanTokenLogicWeth, {"from": deployer})
iETHProxy = Contract.from_abi("iETHProxy", address="0x206C689DC38c84cc7B54cd7c81c4F24ee3388731", abi=LoanToken.abi)
iETH = Contract.from_abi("iETH", iETHProxy, loanTokenLogicWeth.abi)
# underlyingSymbol = "ETH"
# iTokenSymbol = "i{}".format(underlyingSymbol)
# iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
# iETH.initialize(WETH, iTokenName, iTokenSymbol, {'from': deployer})
#iETH.initializeDomainSeparator({"from": deployer})

#BZX.setLoanPool([iUSDC, iETH], [USDC, WETH], {"from": deployer})
#BZX.setSupportedTokens([USDC, WETH], [True, True], True, {"from": deployer})

exec(open("./scripts/env/set-goerly-base.py").read())
MINIMAL_RATES = {
    "iETH":   0.1e18,
    "iUSDC":  0.8e18
}
#
# supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
# loanTokensArr = []
# collateralTokensArr = []
# amountsArr = []
# params = []
#
# for l in list:
#     BZX.setupLoanPoolTWAI(l[0], {'from': deployer})
#
# for tokenAssetPairA in supportedTokenAssetsPairs:
#     params.clear()
#     loanTokensArr.clear()
#     collateralTokensArr.clear()
#     amountsArr.clear()
#
#     # below is to allow new iToken.loanTokenAddress in other existing iTokens
#     existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
#     existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
#     print("itoken", existingIToken.name(), tokenAssetPairA[0])
#
#     for tokenAssetPairB in supportedTokenAssetsPairs:
#         collateralTokenAddress = tokenAssetPairB[1]
#
#         if collateralTokenAddress == existingITokenLoanTokenAddress:
#             continue
#
#         loanTokensArr.append(existingITokenLoanTokenAddress)
#         collateralTokensArr.append(collateralTokenAddress)
#         amountsArr.append(7*10**18)
#
#     BZX.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": deployer})
#
#
# for assetPair in supportedTokenAssetsPairs:
#     existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
#     print("itoken", existingIToken.symbol(), assetPair[0])
#     CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(existingIToken.symbol()), MINIMAL_RATES.get(existingIToken.symbol())), existingIToken, {"from": deployer})
#     existingIToken.setDemandCurve(CUI,{"from": deployer})

assert False
