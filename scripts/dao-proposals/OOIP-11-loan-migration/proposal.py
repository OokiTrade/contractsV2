exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *


# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-11 DAO proposal to migrate loans to new interest model"


TIMELOCK = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
APE_TOKEN = '0x4d224452801aced8b2f0aebe155379bb5d594381'
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
    pushToCalldata(iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))

    if(token.allowance(iToken, BZX)==0):
        calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
        print("initialize::calldata", calldata)
        print("initialize", iToken.name())
        pushToCalldata(iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(settngsLowerAdmin, iToken, CUI):
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    pushToCalldata(iToken.address, iToken.updateSettings.encode_input(settngsLowerAdmin.address, calldata))

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
pushToCalldata(BZX.address, BZX.setTWAISettings.encode_input(60,10800))


print("Redeploying iToken")
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)

iToken = Contract.from_abi("existingIToken", address="0x5c5d12feD25160942623132325A839eDE3F4f4D9", abi=LoanTokenLogicStandard.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    print("")
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
            ['0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
            '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
            '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
            '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
            '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x6B175474E89094C44Da98b954EedeAC495271d0F', 
             '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', 
             '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', 
             '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', 
             '0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD',
             '0xdd974D5C2e2928deA5F71b9825b8b646686BD200', 
             '0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2', 
             '0x56d811088235F11C8920698a204A5010a788f4b3', 
             '0x514910771AF9Ca656af840dff83E8264EcF986CA', 
             '0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e',
             '0xdAC17F958D2ee523a2206206994597C13D831ec7', 
             '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9', 
             '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984', 
             '0xc00e94Cb662C3520282E6f5717214004A7f26888'],

            ['0x6B175474E89094C44Da98b954EedeAC495271d0F', 
            '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', 
            '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', 
            '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', 
            '0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD',
             '0xdd974D5C2e2928deA5F71b9825b8b646686BD200', 
             '0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2', 
             '0x56d811088235F11C8920698a204A5010a788f4b3', 
             '0x514910771AF9Ca656af840dff83E8264EcF986CA', 
             '0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e',
             '0xdAC17F958D2ee523a2206206994597C13D831ec7', 
             '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9', 
             '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984', 
             '0xc00e94Cb662C3520282E6f5717214004A7f26888', 
             '0x0De05F6447ab4D22c8827449EE4bA2D5C288379B',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381',
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381', 
             '0x4d224452801ACEd8B2F0aebE155379bb5D594381'],
            [7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000,
             7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000,
             7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000, 7000000000000000000]
        ))
    print("Update curve", existingIToken)
    updateMarginSettings(settngsLowerAdmin, existingIToken, CUI)
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

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
print("Create proposal")
DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG})
calldata = DAO.propose.encode_input(targets, values, signatures, calldatas, description)

