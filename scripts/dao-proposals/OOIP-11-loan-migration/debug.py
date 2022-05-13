exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *


# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-11 DAO proposal to migrate loans to new interest model"

def replaceIToken(settings, itoken, token, loanTokenLogicStandard):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken: ", iToken.name())

    print("setTarget", loanTokenLogicStandard)
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': TIMELOCK})

    if(token.allowance(iToken, BZX)==0):
        calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
        print("initialize::calldata", calldata)
        print("initialize", iToken.name())
        iToken.updateSettings(settings, calldata, {"from": TIMELOCK})
    return iToken

def updateMarginSettings(settngsLowerAdmin, iToken, CUI):
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    iToken.updateSettings(settngsLowerAdmin, calldata,{"from": TIMELOCK})

gas_price = Wei("50 gwei")

## TickMathV1 deploy
tickMath = TickMathV1.deploy({"from": deployer})

## ProtocolPausableGuardian
guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer})
#guardianImpl = Contract.from_abi("guardianImpl", address="0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", abi=ProtocolPausableGuardian.abi)

## LoanSettings
settingsImpl = LoanSettings.deploy({'from': deployer})
#settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)

## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer})
#openingsImpl = Contract.from_abi("openingsImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanOpenings.abi)

## LoanMaintenance
maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer})
#maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)

## LoanMigration
migrationImpl = LoanMigration.deploy({'from': deployer})
#migrationImpl = Contract.from_abi("maintenaceImpl", address="0x4416883645E26EB91D62EB1B9968f925d8388C44", abi=LoanMigration.abi)

## LoanMaintenance
maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
#maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)

## LoanClosings
closingImpl = LoanClosings.deploy({'from': deployer})
#closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)

## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer})
#swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)

## ProtocolSettings
protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer})
#protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", abi=ProtocolSettings.abi)

print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer})
univ2 = SwapsImplUniswapV2_ETH.deploy({'from':deployer})
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
dex_record.setDexID(univ2.address, {'from':deployer})
dex_record.setDexID(univ3.address, {'from':deployer})
dex_record.transferOwnership(TIMELOCK, {'from': deployer})
#dex_record = Contract.from_abi("dex_record", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=DexRecords.abi)


# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer})
#CUI = Contract.from_abi("CurvedInterestRate", address="0xDbf57A4Cf3d460D8e379dd9fAfbc7A62Af5e653e", abi=CurvedInterestRate.abi)

# Deploy LoanTokenSettings
settngs = deployer.deploy(LoanTokenSettings)
#settngs = Contract.from_abi("settngs", address="0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", abi=LoanTokenSettings.abi)

# Deploy LoanTokenSettingsLowerAdmin
settngsLowerAdmin = deployer.deploy(LoanTokenSettingsLowerAdmin)
#settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenSettingsLowerAdmin.abi)

loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': deployer}).address
#loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53", abi=LoanTokenLogicStandard.abi)

loanTokenLogicWeth = LoanTokenLogicWeth.deploy({'from': deployer}).address
#loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)


ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)

BZX.replaceContract(settingsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(guardianImpl.address, {'from': TIMELOCK})
BZX.replaceContract(openingsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(maintenace2Impl.address, {'from': TIMELOCK})
BZX.replaceContract(migrationImpl.address, {'from': TIMELOCK})
BZX.replaceContract(maintenaceImpl.address, {'from': TIMELOCK})
BZX.replaceContract(closingImpl.address, {'from': TIMELOCK})
BZX.replaceContract(swapsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(protocolsettingsImpl.address, {'from': TIMELOCK})
BZX.setSwapsImplContract(dex_record.address, {'from':TIMELOCK})
pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": TIMELOCK})
BZX.setTWAISettings(60,10800, {'from':BZX.owner()})

print("Redeploying iToken")
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    if(existingIToken == iOOKI):
        continue
    if(existingIToken == iETH):
        print("WET logic")
        replaceIToken(settngs, existingIToken, existingToken, loanTokenLogicWeth)
    else:
        replaceIToken(settngs, existingIToken, existingToken, loanTokenLogicStandard)

    if(tokenAssetPairA[1] == APE_TOKEN):
        print("setLiquidationIncentivePercent for iAPE", existingIToken)
        pushToCalldata(BZX.address, BZX.setLiquidationIncentivePercent.encode_input(
            ['0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381', '0x4d224452801ACEd8B2F0aebE155379bb5D594381'],
            ['0x6B175474E89094C44Da98b954EedeAC495271d0F', '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', '0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD', '0xdd974D5C2e2928deA5F71b9825b8b646686BD200',
             '0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2', '0x56d811088235F11C8920698a204A5010a788f4b3', '0x514910771AF9Ca656af840dff83E8264EcF986CA', '0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e', '0xdAC17F958D2ee523a2206206994597C13D831ec7', '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9',
             '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984', '0xc00e94Cb662C3520282E6f5717214004A7f26888', '0x0De05F6447ab4D22c8827449EE4bA2D5C288379B', '0x6B175474E89094C44Da98b954EedeAC495271d0F', '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
             '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', '0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD', '0xdd974D5C2e2928deA5F71b9825b8b646686BD200', '0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2', '0x56d811088235F11C8920698a204A5010a788f4b3', '0x514910771AF9Ca656af840dff83E8264EcF986CA',
             '0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e', '0xdAC17F958D2ee523a2206206994597C13D831ec7', '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9', '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984', '0xc00e94Cb662C3520282E6f5717214004A7f26888'],
            [7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000,
             7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000,
             7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000]
        ))

    print("Update curve", existingIToken)
    BZX.setupLoanPoolTWAI(existingIToken, {"from": TIMELOCK})
updateMarginSettings(settngsLowerAdmin, existingIToken, CUI)

#Pause protocol
protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
    BZX.liquidate.signature,
    BZX.depositCollateral.signature,
    BZX.withdrawCollateral.signature,
    BZX.settleInterest.signature
]

print("Pause protocol")
BZX.pause(protocolPauseSignatures, {'from': TIMELOCK})


def migrate(iToken, migrator):
    end = migrator.getLoanCount(iToken)
    count = 10
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        migrator.migrateLoans(iToken,count * x, count, {'from': TIMELOCK})


#Add iAPE, that will be executed in ooip-10
supportedTokenAssetsPairs = []
for x in TOKEN_REGISTRY.getTokens(0, 100):
    supportedTokenAssetsPairs.append(x)
supportedTokenAssetsPairs.append(("0x5c5d12feD25160942623132325A839eDE3F4f4D9", "0x4d224452801aced8b2f0aebe155379bb5d594381"))

migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    if(existingIToken == iOOKI):
        continue
    migrate(existingIToken, migrator)

BZX.unpause(protocolPauseSignatures, {'from': TIMELOCK})
