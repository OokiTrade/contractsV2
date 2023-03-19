# TUSD = "0xad5bAD2C6E9B809a74fA65B52850aa179160818f"
# ZERO_ADDRESS="0x0000000000000000000000000000000000000000"
# #bZxProtocol.deploy({'from': deployer})
# BZX = Contract.from_abi("BZX", "0x5D90e4D6152F3B0dd326df479E0f6DBA2Af57FD5", interface.IBZx.abi)
# #TokenRegistry.deploy({'from': deployer})
# TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0xB73660CC7a358ADffDEb6996deddD561D8EAE36f", TokenRegistry.abi)
# ZERO_ADDRESS="0x0000000000000000000000000000000000000000"
#
# #TickMathV1.deploy({'from': deployer})
# tickMath = TickMathV1.at("0x51d355b03b265B506796fCfaF2082c932fBa289d")
# #VolumeTracker.deploy({'from': deployer})
# volumeTracker = VolumeTracker.at("0x6a4767d6Ed0dD30a037D2209a69a3C64B8Ead583")
# #LiquidationHelper.deploy({'from': deployer})
# liquidationHelper = LiquidationHelper.at("0xD11a31a395866767C6cDf4B0D7A4dffe3FCa1FF4")
#
# #HelperImpl.deploy({"from": deployer})
# #helperImpl = HelperImpl.at("0x4549ac05737270154F6855F13fFbac1367ed0705")
# #HelperProxy.deploy(helperImpl, {"from": deployer})
# HELPER = Contract.from_abi("HELPER", "0xc21669005E8a8580E38fa0e06CE24B6634F4F7AC", HelperImpl.abi)
#
# #Receiver.deploy({"from": deployer})
# receiver = Contract.from_abi("Receiver", "0xE8dFBeF6a7b2C48BC154C8F57fB4363fe057B1D7", Receiver.abi)
#
# ## LoanSettings
# #LoanSettings.deploy({'from': deployer})
# settingsImpl = Contract.from_abi("settingsImpl", address="0x809f126497262078f6aae0Ae4B36aFD67F3f6702", abi=LoanSettings.abi)
#
# ## LoanOpenings
# #LoanOpenings.deploy({'from': deployer})
# openingsImpl = Contract.from_abi("openingsImpl", address="0x61aAf25028C07AEB6c895A9fEB8D695C6D003722", abi=LoanOpenings.abi)
#
# ## LoanMaintenance
# #LoanMaintenance_2.deploy({'from': deployer})
# maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x0726854e6F73f21E781f9ef8eB36Bad801072f0b", abi=LoanMaintenance_2.abi)
#
# ## LoanMaintenance
# #maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
# maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x6D235015042ead928216b62650ec8459b363Ec26", abi=LoanMaintenance.abi)
#
# ## LoanClosings
# #LoanClosings.deploy({'from': deployer})
# closingImpl = Contract.from_abi("closingImpl", address="0x8839f57e93B92B251D2Ad1931398B0Ae1c51561D", abi=LoanClosings.abi)
#
# ## SwapsExternal
# #SwapsExternal.deploy({'from': deployer})
# swapsImpl = Contract.from_abi("swapsImpl", address="0x34bb0E89363C9baf64e9f737ADa646cDE8F47709", abi=SwapsExternal.abi)
#
# #PriceFeeds.deploy({"from": deployer})
# pricefeeds = Contract.from_abi('priceFeeds', "0x1b2bf52a094B96B82F42eA162ee6F6852dD7fFc5", PriceFeeds.abi)
#
# ## ProtocolSettings
# #ProtocolSettings.deploy({'from': deployer})
# protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0x765e92de3B0dBf8ae616a2B573CE6F71309300E7", abi=ProtocolSettings.abi)
#
# BZX.replaceContract(protocolsettingsImpl.address, {'from': deployer})
# BZX.replaceContract(settingsImpl.address, {'from': deployer})
# BZX.replaceContract(openingsImpl.address, {'from': deployer})
# BZX.replaceContract(maintenace2Impl.address, {'from': deployer})
# BZX.replaceContract(maintenaceImpl.address, {'from': deployer})
# BZX.replaceContract(closingImpl.address, {'from': deployer})
# BZX.replaceContract(swapsImpl.address, {'from': deployer})
# BZX.setPriceFeedContract(pricefeeds.address, {'from': deployer})
#
#
# #CurvedInterestRate.deploy({'from':deployer})
# CUI = Contract.from_abi("CurvedInterestRate", address="0x3b015a7158E2AD4E7d8557fC1A60ED2002AbdF04", abi=CurvedInterestRate.abi)
#
# #ArbitraryCaller.deploy({'from': deployer})
# #LoanTokenSettingsLowerAdmin.deploy({'from': deployer})
# settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x023C20864f5bf97f83dc667cf44fd2ebea972555", abi=LoanTokenSettingsLowerAdmin.abi)
#
# #LoanTokenLogicStandard.deploy({'from': deployer})
# loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0xe5495dE5b0Fdef7326EC5F89972e8c80Be11F6fa", abi=LoanTokenLogicStandard.abi)
#
# #LoanTokenLogicWeth.deploy({'from': deployer})
# loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x09A7AC3F1AD71D2fcc1b93245D3834C4339B589A", abi=LoanTokenLogicWeth.abi)
#
#
# #DexRecords.deploy({'from':deployer})
# dex_record = Contract.from_abi("dex_record", address="0x86Cb2983da3D78f91dE2523c37c26412AC10280e", abi=DexRecords.abi)
# #SwapsImplUniswapV2_GOERLYBASE.deploy({'from':deployer})
# univ2 = Contract.from_abi("SwapsImplUniswapV2_GOERLYBASE", address="0xa08EBbe25e654Df05db42BaB110036efBA78a462", abi=SwapsImplUniswapV2_GOERLYBASE.abi)
# #dex_record.setDexID(univ2.address, {'from':deployer})
#
# BZX.setSwapsImplContract(dex_record, {'from': deployer})
# BZX.setTWAISettings(60,10800, {'from':BZX.owner()})
#
# WETH = '0x4200000000000000000000000000000000000006'
# TUSD = '0xad5bAD2C6E9B809a74fA65B52850aa179160818f'
# ethPriceFeed = '0xcD2A119bD1F7DF95d706DE6F2057fDD45A0503E2' #Chainlink
# tusdPriceFeed = '0xb85765935B4d9Ab6f841c9a00690Da5F34368bc0' #Chainlink
# pricefeeds.setPriceFeed([WETH], [ethPriceFeed], {"from": deployer})
# pricefeeds.setPriceFeed([TUSD], [tusdPriceFeed], {"from": deployer})
# pricefeeds.setDecimals([TUSD, WETH], {"from": deployer})
# BZX.setApprovals([TUSD, WETH], [1], {'from': deployer})

#iTUSD
#LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
iTUSDProxy = Contract.from_abi("iTUSDProxy", address="0x3F2aa02380fE061042b042D16beB9adF8e5191ba", abi=LoanToken.abi)
iTUSD = Contract.from_abi("iTUSD", iTUSDProxy, LoanTokenLogicStandard.abi)
# underlyingSymbol = "TUSD"
# iTokenSymbol = "i{}".format(underlyingSymbol)
# iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
# iTUSD.initialize(TUSD, iTokenName, iTokenSymbol, {'from': deployer})
# iTUSD.initializeDomainSeparator({"from": deployer})

#iETH
#LoanToken.deploy(deployer, loanTokenLogicWeth, {"from": deployer})
iETHProxy = Contract.from_abi("iETHProxy", address="0x5596D7435C887D0e7009aD5454c5C89b950cc384", abi=LoanToken.abi)
iETH = Contract.from_abi("iETH", iETHProxy, loanTokenLogicWeth.abi)
# underlyingSymbol = "ETH"
# iTokenSymbol = "i{}".format(underlyingSymbol)
# iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
# iETH.initialize(WETH, iTokenName, iTokenSymbol, {'from': deployer})
# iETH.initializeDomainSeparator({"from": deployer})

# BZX.setLoanPool([iTUSD, iETH], [TUSD, WETH], {"from": deployer})
# BZX.setSupportedTokens([TUSD, WETH], [True, True], True, {"from": deployer})

exec(open("./scripts/env/set-goerly-base.py").read())
MINIMAL_RATES = {
    "iETH":   0.1e18,
    "iTUSD":  0.8e18
}

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
loanTokensArr = []
collateralTokensArr = []
amountsArr = []
params = []

for l in list:
    BZX.setupLoanPoolTWAI(l[0], {'from': deployer})

for tokenAssetPairA in supportedTokenAssetsPairs:
    params.clear()
    loanTokensArr.clear()
    collateralTokensArr.clear()
    amountsArr.clear()

    # below is to allow new iToken.loanTokenAddress in other existing iTokens
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
    print("itoken", existingIToken.name(), tokenAssetPairA[0])

    for tokenAssetPairB in supportedTokenAssetsPairs:
        collateralTokenAddress = tokenAssetPairB[1]
        if collateralTokenAddress == existingITokenLoanTokenAddress:
            continue


        existingToken = Contract.from_abi("existingToken", address=existingITokenLoanTokenAddress, abi=TestToken.abi)
        collateralToken = Contract.from_abi("collateralToken", address=collateralTokenAddress, abi=TestToken.abi)
        print(existingToken.name(), " ", collateralToken.name())
        loanParam = [BZX.generateLoanParamId(existingToken, collateralToken, True), True, ZERO_ADDRESS, existingToken, collateralToken, 10e18, 7e18, 0]
        BZX.modifyLoanParams([loanParam], {"from": deployer})
        loanParam = [BZX.generateLoanParamId(existingToken, collateralToken, False), True, ZERO_ADDRESS, existingToken, collateralToken, 10e18, 7e18, 1]
        BZX.modifyLoanParams([loanParam], {"from": deployer})

        loanTokensArr.append(existingITokenLoanTokenAddress)
        collateralTokensArr.append(collateralTokenAddress)
        amountsArr.append(7*10**18)

    BZX.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": deployer})


for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    print("itoken", existingIToken.symbol(), assetPair[0])
    CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(existingIToken.symbol()), MINIMAL_RATES.get(existingIToken.symbol())), existingIToken, {"from": deployer})
    existingIToken.setDemandCurve(CUI,{"from": deployer})

assert False