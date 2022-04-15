from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]

loanTokenLogicStandard = "0xfb772316a54dcd439964b561Fc2c173697AeEb5b"
iTokenProxy = Contract.from_abi("LoanTokenLogicStandard", address="0x5c5d12feD25160942623132325A839eDE3F4f4D9", abi=LoanToken.abi)
# "0x5c5d12feD25160942623132325A839eDE3F4f4D9" #LoanToken.deploy(deployer, loanTokenLogicStandard, {'from': deployer})

print("Deploying iToken")
iToken = Contract.from_abi("LoanTokenLogicStandard", address=iTokenProxy, abi=LoanTokenLogicStandard.abi)
APE_TOKEN = '0x4d224452801aced8b2f0aebe155379bb5d594381'
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