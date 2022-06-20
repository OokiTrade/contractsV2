import time
deployer = accounts.load('deployer')
params  = {'from': deployer}
BZX = Contract.from_abi("BZX", "0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", bZxProtocol.abi)

#
dai_Pricefeed = "0x8dBa75e83DA73cc766A7e5a0ee71F656BAb470d6" # dai
usdt_Pricefeed = "0xECef79E109e997bCA29c1c0897ec9d7b03647F5E" # usdt
usdc_Pricefeed = "0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3" # usdc
weth_Pricefeed = "0x13e3Ee699D1909E989722E753853AE30b17e08c5" # weth
wbtc_Pricefeed = "0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593" # wbtc
frax_Pricefeed = "0xc7D132BeCAbE7Dcc4204841F33bae45841e41D9C" # frax
# op_Pricefeed = "0x3B2AF9149360e9F954C18f280aD0F4Adf1B613b8" # usdc

#
idai = "0xE60d6142D3d683a58B02337E1F0D08C69B946aCF"
iusdt = "0x32246a17896d8b7aEc4AC4EDc3f5899D0f066855"
iusdc = "0xBFcf8755Ba9d23F7F0EBbA0da70819A907dA2aCC"
ieth = "0x10b158EDF554dc15dCdBFd93049759e6e35c1384"
ibtc = "0x0515fDe94bb95d6A5b7640f8F0d3AC98C9390903"
ifrax = "0x1dbc7f43d432C8E92762FC9680A5BcF4646FB5e5"

#
dai = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1" # dai
usdt = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58" # usdt
usdc = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607" # usdc
weth = "0x4200000000000000000000000000000000000006" # weth
wbtc = "0x68f180fcCe6836688e9084f035309E29Bf0A2095" # wbtc
frax = "0x2E3D870790dC77A83DD1d18184Acc7439A53f475" # wbtc
# op = "0x4200000000000000000000000000000000000042" # op

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
loanTokenSettings = Contract.from_abi("settings", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenSettings.abi)

# # Deploy LoanTokenSettingsLowerAdmin
#settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy(params, publish_source=True)
settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x46530E77a3ad47f432D1ad206fB8c44435932B91", abi=LoanTokenSettingsLowerAdmin.abi)

#loanTokenLogicStandard = LoanTokenLogicStandard.deploy(params, publish_source=True)
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0xc2cC7403905B6B49BF891Ab3679b15F77AD743B6", abi=LoanTokenLogicStandard.abi)

#loanTokenLogicweth = LoanTokenLogicWeth.deploy(params, publish_source=True)
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0x5690974015fc2b7a7EBB277BC377507d8Db43c2b", abi=LoanTokenLogicWeth.abi)


#helperImpl = HelperImpl.deploy(params, publish_source=True)
#helperImpl = Contract.from_abi("HelperImpl", "0xD039fc87407d3062D05a974C5f16550e2BaBDE4e", HelperImpl.abi)
#helper = HelperProxy.deploy(helperImpl.address, params, publish_source=True)
HELPER = Contract.from_abi("HELPER", "0x3920993FEca46AF170d296466d8bdb47A4b4e152", HelperImpl.abi)

#univ3 = SwapsImplUniswapV3_ETH.deploy(params)
univ3 = Contract.from_abi("SwapsImplUniswapV3_ETH", "0x7Ec3888aaF6Fe27E73742526c832e996Eb8fd7Fe", SwapsImplUniswapV3_ETH.abi)

## PriceFeeds
# print("Deploying PriceFeeds.")
# feeds = PriceFeeds_OPTIMISM.deploy(params)
feeds = Contract.from_abi("feeds", address="0x723bD1672b4bafF0B8132eAfc082EB864cF18D24", abi=PriceFeeds_OPTIMISM.abi)


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
