from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]
description = "OOIP-10 iAPE"
APE_TOKEN = '0x4d224452801aced8b2f0aebe155379bb5d594381'
def marginSettings(supportedTokenAssetsPairs):
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
    for tokenAssetPairA in supportedTokenAssetsPairs:
        params.clear()
        loanTokensArr.clear()
        collateralTokensArr.clear()
        amountsArr.clear()
        # below is to allow new iToken.loanTokenAddress in other existing iTokens
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()


        #only ASP
        if existingITokenLoanTokenAddress != loanToken.address:
            print("marginSettings::itoken", existingIToken.name(), existingITokenLoanTokenAddress, 'skip')
            continue

        print("marginSettings::itoken", existingIToken.name(), existingITokenLoanTokenAddress)
        for tokenAssetPairB in supportedTokenAssetsPairs:
            collateralTokenAddress = tokenAssetPairB[1]
            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            base_data_copy = base_data.copy()
            base_data_copy[3] = existingITokenLoanTokenAddress
            base_data_copy[4] = collateralTokenAddress # pair is iToken, Underlying

            base_data_copy[5] = Wei("20 ether")  # minInitialMargin
            base_data_copy[6] = Wei("15 ether")  # maintenanceMargin

            params.append(base_data_copy)

            loanTokensArr.append(existingITokenLoanTokenAddress)
            collateralTokensArr.append(collateralTokenAddress)
            amountsArr.append(7*10**18)

        print(params)
        if (len(params) != 0):
            ## Torque loans
            calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, True)
            targets.append(existingIToken.address)
            calldatas.append(existingIToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata))

            ## Margin trades
            calldata = LOAN_TOKEN_SETTINGS_ADMIN.setupLoanParams.encode_input(params, False)
            targets.append(existingIToken.address)
            calldatas.append(existingIToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata))

        targets.append(BZX.address)
        calldatas.append(BZX.setLiquidationIncentivePercent.encode_input(loanTokensArr, collateralTokensArr, amountsArr))

targets = []
values = []
calldatas = []

# accounts.load()

# 1. deploy 1APE
loanTokenLogicStandard = "0xfb772316a54dcd439964b561Fc2c173697AeEb5b"
iTokenProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {'from': deployer})

print("Deploying iToken")
iToken = Contract.from_abi("existingIToken", address=iTokenProxy, abi=LoanTokenLogicStandard.abi)
loanToken = Contract.from_abi("token", address=APE_TOKEN, abi=TestToken.abi)
underlyingSymbol = loanToken.symbol()
iTokenSymbol = "i{}".format(underlyingSymbol)
iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)


calldata = LOAN_TOKEN_SETTINGS.initialize.encode_input(loanToken, iTokenName, iTokenSymbol)
print("initialize::calldata", calldata)
print("initialize", iToken.name())
iToken.updateSettings(LOAN_TOKEN_SETTINGS, calldata, {'from': deployer})

calldata = LOAN_TOKEN_SETTINGS.setLowerAdminValues.encode_input(
    TIMELOCK, # guardian multisig
    LOAN_TOKEN_SETTINGS_ADMIN  # LOAN_TOKEN_SETTINGS_ADMIN contract
)
iToken.updateSettings(LOAN_TOKEN_SETTINGS, calldata, {'from': deployer})

calldata = LOAN_TOKEN_SETTINGS_ADMIN.setDemandCurve.encode_input(0, 20*10**18, 0, 0, 60*10**18, 80*10**18, 120*10**18)
iToken.updateSettings(LOAN_TOKEN_SETTINGS_ADMIN.address, calldata, {'from': deployer})
iToken.transferOwnership(TIMELOCK, {'from': deployer})

# 2. Add pricefeed to protocol
targets.append(PRICE_FEED.address)
calldatas.append(PRICE_FEED.setPriceFeed.encode_input([APE_TOKEN], ['0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18']))

targets.append(BZX.address)
calldatas.append(BZX.setLoanPool.encode_input([iToken], [iToken.loanTokenAddress()]))

targets.append(BZX.address)
calldatas.append(BZX.setSupportedTokens.encode_input([iToken.loanTokenAddress()], [True], True))

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
pairs = []
for x in supportedTokenAssetsPairs:
    pairs.append(x)
pairs.append((iToken.address, iToken.address))

marginSettings(pairs)


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
TEAM_VOTING_MULTISIG = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"

# Make proposal
OOKI.approve(STAKING, 2**256-1, {'from': '0xF977814e90dA44bFA03b6295A0616a897441aceC'})
STAKING.stake([OOKI], [100e25], {'from': '0xF977814e90dA44bFA03b6295A0616a897441aceC'})
call = DAO.propose(targets, values, signatures, calldatas, description, {"from": '0xF977814e90dA44bFA03b6295A0616a897441aceC'})
print("call", call)