exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *


# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-9 DAO proposal to migrate loans to new interest model"


GUARDIAN_TIMELOCK = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"

targets = []
values = []
calldatas = []

def pushToCalldata(target, calldata):
    targets.append(target)
    calldatas.append(calldata)

def replaceIToken(settings, itoken, token, loanTokenLogicStandard):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken: ", iToken.name())

    print("setTarget", loanTokenLogicStandard)
    #iTokenProxy.setTarget(loanTokenLogicStandard, {'from': GUARDIAN_TIMELOCK})
    pushToCalldata(iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))

    if(token.allowance(iToken, BZX)==0):
        calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
        print("initialize::calldata", calldata)
        print("initialize", iToken.name())
        #iToken.updateSettings(settings, calldata, {"from": GUARDIAN_TIMELOCK})
        pushToCalldata(iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(settngsLowerAdmin, iToken, CUI):
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    #iToken.updateSettings(settngsLowerAdmin, calldata,{"from": GUARDIAN_TIMELOCK})
    pushToCalldata(iToken.address, iToken.updateSettings.encode_input(settngsLowerAdmin.address, calldata))

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
dex_record.transferOwnership(GUARDIAN_TIMELOCK, {'from': deployer})
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

pushToCalldata(BZX.address, BZX.replaceContract.encode_input(settingsImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(guardianImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(openingsImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(maintenace2Impl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(migrationImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(maintenaceImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(closingImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(swapsImpl.address))
pushToCalldata(BZX.address, BZX.replaceContract.encode_input(protocolsettingsImpl.address))
pushToCalldata(BZX.address, BZX.setSwapsImplContract.encode_input(dex_record.address))
pushToCalldata(pricefeeds.address, pricefeeds.setPriceFeed.encode_input([OOKI],[ookiPriceFeed]))

#BZX.replaceContract(settingsImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(guardianImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(openingsImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(maintenace2Impl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(migrationImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(maintenaceImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(closingImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(swapsImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.replaceContract(protocolsettingsImpl.address, {'from': GUARDIAN_TIMELOCK})
#BZX.setSwapsImplContract(dex_record.address, {'from':GUARDIAN_TIMELOCK})
#pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_TIMELOCK})

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
    print("Update curve", existingIToken)
    updateMarginSettings(settngsLowerAdmin, existingIToken, CUI)
    #BZX.setupLoanPoolTWAI(existingIToken, {"from": GUARDIAN_GUARDIAN_TIMELOCK})
    pushToCalldata(BZX.address, BZX.setupLoanPoolTWAI.encode_input(existingIToken))

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
pushToCalldata(BZX.address, BZX.pause.encode_input(protocolPauseSignatures))
#BZX.pause(protocolPauseSignatures, {'from': GUARDIAN_TIMELOCK})

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG})
calldata = DAO.propose.encode_input(targets, values, signatures, calldatas, description)

#safe = ApeSafe(GUARDIAN_MULTISIG)

gasUsed = 0
for x in range(0, len(calldatas)):
    tx = history[x+1]
    gasUsed = gasUsed + tx.gas_used