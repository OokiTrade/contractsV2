deployer = accounts.load('deployer')
params  = {'from': deployer}
BZX = Contract.from_abi("BZX", "0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", bZxProtocol.abi)

#
# dai_FluxPricefeed = "0xb235ff2D8B8ccD4a4a5c16c9689014d6D2BF2A76" # dai
# usdt_FluxPricefeed = "0x8FeAE79dB32595d8Ee57D40aA7De0512cBe36625" # usdt
# usdc_FluxPricefeed = "0x3B2AF9149360e9F954C18f280aD0F4Adf1B613b8" # usdc
# weth_FluxPricefeed = "0x4C8f111a1048fEc7Ea9c9cbAB96a2cB5d1B94560" # weth
# wbtc_FluxPricefeed = "0x08fDc3CE77f4449D26461A70Acc222140573956e" # wbtc
#
# idai = "0x206C689DC38c84cc7B54cd7c81c4F24ee3388731"
# iusdt = "0xD15667cB9A2d2c6D8Acabb6c138B936c6642b0E5"
# iusdc = "0xec260573e04186714E39a24786e7bBb2AB3E73d7"
# ieth = "0xc3190c617569441D63c3cBd571CA1346Ac866478"
# ibtc = "0x3cA8b998712278342b07b94d4f1FE8DEb88c1b7F"
#
# dai = "0x63743ACF2c7cfee65A5E356A4C4A005b586fC7AA" # dai
# usdt = "0x7FF4a56B32ee13D7D4D405887E0eA37d61Ed919e" # usdt
# usdc = "0x51e44FfaD5C2B122C8b635671FCC8139dc636E82" # usdc
# weth = "0x5842C5532b61aCF3227679a8b1BD0242a41752f2" # weth
# wbtc = "0xF80699Dc594e00aE7bA200c7533a07C1604A106D" # wbtc




#TOKEN_REGISTRY = TokenRegistry.deploy(params, publish_source=True)
TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", TokenRegistry.abi)
#########################

#tickMath = TickMathV1.deploy(params, publish_source=True)
tickMath = Contract.from_abi("TickMathV1", "0x3D87106A93F56ceE890769A808Af62Abc67ECBD3", TickMathV1.abi)

# ## ProtocolPausableGuardian
#guardianImpl = ProtocolPausableGuardian.deploy(params, publish_source=True)
guardianImpl = Contract.from_abi("guardianImpl", address="0xE4Ac87b95FFb28FDCb009009b4eDF949702f1785", abi=ProtocolPausableGuardian.abi)

 # LoanSettings require mathTick
#loanSettingsImpl = LoanSettings.deploy(params, publish_source=True)
loanSettingsImpl = Contract.from_abi("settingsImpl", address="0x1Ab4bc72BC67EE63c2EA2548798786E330Ae1A31", abi=LoanSettings.abi)

# ## LoanOpenings
#openingsImpl = LoanOpenings.deploy(params, publish_source=True)
openingsImpl = Contract.from_abi("openingsImpl", address="0x13f2d2053E20Ff8d20fb63bf2647515ec330d731", abi=LoanOpenings.abi)

# ## LoanMaintenance require mathTick
#maintenace2Impl = LoanMaintenance_2.deploy(params, publish_source=True)
maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0xF93118c86370A9bd722F6D6E8Df9ebE05e5e854B", abi=LoanMaintenance_2.abi)

# # ## LoanMaintenance require mathTick
#maintenaceImpl = LoanMaintenance.deploy(params, publish_source=True)
maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x650980C7CB878629Bda2C33828A8F729B9B8635c", abi=LoanMaintenance.abi)

## LoanClosings
#closingImpl = LoanClosings.deploy(params, publish_source=True)
closingImpl = Contract.from_abi("closingImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanClosings.abi)

# ## SwapsExternal
#swapsExternal = SwapsExternal.deploy(params, publish_source=True)
swapsExternal = Contract.from_abi("SwapsExternal", "0x4416883645E26EB91D62EB1B9968f925d8388C44", SwapsExternal.abi)

# ## ProtocolSettings
#protocolsettingsImpl = ProtocolSettings.deploy(params, publish_source=True)
protocolsettingsImpl = Contract.from_abi("ProtocolSettings", "0xDbf57A4Cf3d460D8e379dd9fAfbc7A62Af5e653e", ProtocolSettings.abi)

# print("Deploying Dex Selector and Implementations")
#dex_record = DexRecords.deploy(params, publish_source=True)

#!!!!! Not verified
dex_record = Contract.from_abi("DexRecords", "0x8FA2c0864fE84D1f56D6C3C33e31E00564425782", DexRecords.abi)

# # Deploy CurvedInterestRate
#CUI = CurvedInterestRate.deploy(params, publish_source=True)
CUI = Contract.from_abi("CurvedInterestRate", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=CurvedInterestRate.abi)

# # Deploy LoanTokenSettings
#loanTokenSettings = LoanTokenSettings.deploy(params, publish_source=True)
#!!!!! Not verified
loanTokenSettings = Contract.from_abi("settings", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenSettings.abi)

# # Deploy LoanTokenSettingsLowerAdmin
#!!!!! Not verified
#settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy(params, publish_source=True)
settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x46530E77a3ad47f432D1ad206fB8c44435932B91", abi=LoanTokenSettingsLowerAdmin.abi)

#loanTokenLogicStandard = LoanTokenLogicStandard.deploy(params, publish_source=True)
#!!!!! Not verified
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0xc2cC7403905B6B49BF891Ab3679b15F77AD743B6", abi=LoanTokenLogicStandard.abi)

#loanTokenLogicweth = LoanTokenLogicWeth.deploy(params, publish_source=True)
#!!!!! Not verified
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x5690974015fc2b7a7EBB277BC377507d8Db43c2b", abi=LoanTokenLogicWeth.abi)


#helperImpl = HelperImpl.deploy(params, publish_source=True)
#helperImpl = Contract.from_abi("HelperImpl", "0x14E62422eA87349e999a8bcbFB9aD107D1BcDf52", HelperImpl.abi)
#helper = HelperProxy.deploy(helperImpl.address, params, publish_source=True)
HELPER = Contract.from_abi("HELPER", "0x3920993FEca46AF170d296466d8bdb47A4b4e152", HelperImpl.abi)

assert False
univ3 = SwapsImplUniswapV3_OPTIMISM.deploy(params)
#univ3 = Contract.from_abi("SwapsImplUniswapV2_EVMOS", "0x13f2d2053E20Ff8d20fb63bf2647515ec330d731", SwapsImplUniswapV3_OPTIMISM.abi)
dex_record.setDexID(univ3.address, params)

#
# BZX.replaceContract(loanSettingsImpl.address, params)
# BZX.replaceContract(guardianImpl.address, params)
# BZX.replaceContract(openingsImpl.address, params)
# BZX.replaceContract(maintenace2Impl.address, params)
# BZX.replaceContract(maintenaceImpl.address, params)
# BZX.replaceContract(closingImpl.address, params)
# BZX.replaceContract(swapsExternal.address, params)
# BZX.replaceContract(protocolsettingsImpl.address, params)
# protocolsettings = Contract.from_abi("ProtocolSettings", BZX, ProtocolSettings.abi)
# protocolsettings.setSwapsImplContract(dex_record.address, params)
# settings = Contract.from_abi("settingsImpl", address=BZX, abi=LoanSettings.abi)
# settings.setTWAISettings(60,10800, params)

bzx = Contract.from_abi("bzx", address=BZX, abi=interface.IBZx.abi)

# bzx.setSupportedTokens(
#     [dai, usdt, usdc, weth, wbtc],
#     [True, True, True, True, True],
#     True,
#     params
# )

## PriceFeeds
print("Deploying PriceFeeds.")
#feeds = PriceFeeds_EVMOS.deploy(params)
feeds = Contract.from_abi("feeds", address="0x10b158EDF554dc15dCdBFd93049759e6e35c1384", abi=PriceFeeds_EVMOS.abi)
# bzx.setPriceFeedContract(
#     feeds.address # priceFeeds
#     ,params
# )
#
# feeds.setPriceFeed(
#     [usdc, usdt, dai, weth, wbtc],
#     [usdc_FluxPricefeed, usdt_FluxPricefeed, dai_FluxPricefeed, weth_FluxPricefeed, wbtc_FluxPricefeed],
#     params
# )
#

# bzx.setLoanPool(
#     [idai, iusdt, iusdc, ieth, ibtc],
#     [dai, usdt, usdc, weth, wbtc],
#     params
# )

exec(open("./scripts/add-token/add-itoken-evmos.py").read())
deployment(loanTokenSettings, settngsLowerAdmin, dai, 'DAI', idai)
deployment(loanTokenSettings, settngsLowerAdmin, usdc, 'USDC', iusdc)
deployment(loanTokenSettings, settngsLowerAdmin, usdt, 'USDT', iusdt)
deployment(loanTokenSettings, settngsLowerAdmin, weth, 'ETH', ieth)
deployment(loanTokenSettings, settngsLowerAdmin, wbtc, 'BTC', ibtc)

marginSettings(TOKEN_REGISTRY, settngsLowerAdmin, idai, [dai, usdc, usdt])
marginSettings(TOKEN_REGISTRY, settngsLowerAdmin, iusdc, [dai, usdc, usdt])
marginSettings(TOKEN_REGISTRY, settngsLowerAdmin, iusdt, [dai, usdc, usdt])
marginSettings(TOKEN_REGISTRY, settngsLowerAdmin, ieth, [dai, usdc, usdt])
marginSettings(TOKEN_REGISTRY, settngsLowerAdmin, ibtc, [dai, usdc, usdt])
demandCurve(bzx, settngsLowerAdmin, idai, CUI)
demandCurve(bzx, settngsLowerAdmin, iusdc, CUI)
demandCurve(bzx, settngsLowerAdmin, iusdt, CUI)
demandCurve(bzx, settngsLowerAdmin, ieth, CUI)
demandCurve(bzx, settngsLowerAdmin, ibtc, CUI)

#bzx.setFeesController("XXXX", params)

#feeds.transferOwnership(GUARDIAN_MULTISIG, params)
#helperProxy.transferOwnership(GUARDIAN_MULTISIG, params)
#dex_record.transferOwnership(GUARDIAN_MULTISIG, params)
