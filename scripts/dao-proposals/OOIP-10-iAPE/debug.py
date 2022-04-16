from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]
description = "OOIP-10 iAPE"
APE_TOKEN = '0x4d224452801aced8b2f0aebe155379bb5d594381'
def marginSettings(supportedTokenAssetsPairs, iToken):
    loanTokenAddress = iToken.loanTokenAddress()
    base_data = [
        b"0x0",  # id
        False,  # active
        str(TIMELOCK),  # owner
        "0x0000000000000000000000000000000000000001",  # loanToken
        "0x0000000000000000000000000000000000000002",  # collateralToken
        Wei("20 ether"),  # minInitialMargin
        Wei("15 ether"),  # maintenanceMargin
        0  # fixedLoanTerm
    ]

    params = []

    loanTokensArr = []
    collateralTokensArr = []
    amountsArr = []

    for tokenAssetPair in supportedTokenAssetsPairs:
        if tokenAssetPair[0] == iToken.address  or tokenAssetPair[0] == OOKI.address:
            continue
        # below is to allow different collateral for new iToken
        base_data_copy = base_data.copy()
        base_data_copy[3] = loanTokenAddress
        base_data_copy[4] = tokenAssetPair[1] # pair is iToken, Underlying
        print(iToken.name(),base_data_copy)
        params.append(base_data_copy)

        loanTokensArr.append(loanTokenAddress)
        collateralTokensArr.append(tokenAssetPair[1])
        amountsArr.append(7*10**18)


    calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, True)
    targets.append(iToken.address)
    iToken.updateSettings(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata, {'from': TIMELOCK})

    targets.append(iToken.address)
    calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, False)
    iToken.updateSettings(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata, {'from': TIMELOCK})
    params.clear()

    for tokenAssetPair in supportedTokenAssetsPairs:
        # below is to allow new iToken.loanTokenAddress in other existing iTokens
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPair[0], abi=LoanTokenLogicStandard.abi)
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()

        if existingITokenLoanTokenAddress == loanTokenAddress or existingITokenLoanTokenAddress == OOKI.address:
            continue

        base_data_copy = base_data.copy()
        base_data_copy[3] = existingITokenLoanTokenAddress
        base_data_copy[4] = loanTokenAddress # pair is iToken, Underlying
        print(existingIToken.name(), base_data_copy)
        params.append(base_data_copy)

        calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, True)
        targets.append(existingIToken.address)
        existingIToken.updateSettings(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata,  {'from': TIMELOCK})

        calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, False)
        targets.append(existingIToken.address)
        existingIToken.updateSettings(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata, {'from': TIMELOCK})

        loanTokensArr.append(loanTokenAddress)
        collateralTokensArr.append(existingITokenLoanTokenAddress)
        amountsArr.append(7*10**18)
        params.clear()


targets = []
values = []
calldatas = []

# accounts.load()

# 1. deploy 1APE
iTokenProxy = Contract.from_abi("iTokenProxy", address="0x5c5d12feD25160942623132325A839eDE3F4f4D9", abi=LoanToken.abi)

print("Deploying iToken")
iToken = Contract.from_abi("existingIToken", address=iTokenProxy, abi=LoanTokenLogicStandard.abi)
loanToken = Contract.from_abi("token", address=APE_TOKEN, abi=TestToken.abi)

iToken.transferOwnership(TIMELOCK, {'from': iTokenProxy.owner()})

# 2. Add pricefeed to protocol
targets.append(PRICE_FEED.address)
PRICE_FEED.setPriceFeed([APE_TOKEN], ['0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18'], {'from': TIMELOCK})

targets.append(BZX.address)
BZX.setLoanPool([iToken], [iToken.loanTokenAddress()], {'from': TIMELOCK})

targets.append(BZX.address)
BZX.setSupportedTokens([iToken.loanTokenAddress()], [True], True, {'from': TIMELOCK})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)


marginSettings(supportedTokenAssetsPairs, iToken)

