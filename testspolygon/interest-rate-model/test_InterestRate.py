#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts
from brownie.convert.datatypes import  Wei
import json

@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS_LOWER_ADMIN(LoanTokenSettingsLowerAdmin):
    return  Contract.from_abi("loanTokenSettingsLowerAdmin", address="0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C", abi=LoanTokenSettingsLowerAdmin.abi)



@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS(accounts, USDT, LoanTokenSettings):
    return Contract.from_abi("loanToken", address="0x3ff9BFe18206f81d073e35072b1c4D61f866663f", abi=LoanTokenSettings.abi)


@pytest.fixture(scope="module")
def BZX(accounts, interface, LoanSettings, LoanOpenings, LoanMaintenance_2, LoanMaintenance, LoanClosings):
    bzx = Contract.from_abi("bzx", address="0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8",
                            abi=interface.IBZx.abi, owner=accounts[0])

    ## LoanSettings
    print("Deploying LoanSettings.")
    loanSettings = LoanSettings.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanSettings.address, {'from': bzx.owner()})


    ## LoanOpenings
    print("Deploying LoanOpenings.")
    loanOpenings = LoanOpenings.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanOpenings.address, {'from': bzx.owner()})

    ## LoanMaintenance
    print("Deploying LoanMaintenance.")
    loanMaintenance2 = LoanMaintenance_2.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance2.address, {'from': bzx.owner()})

    ## LoanMaintenance
    print("Deploying LoanMaintenance.")
    loanMaintenance = LoanMaintenance.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance.address, {'from': bzx.owner()})


    ## LoanClosings
    print("Deploying LoanClosings.")
    loanClosings = LoanClosings.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanClosings.address, {'from': bzx.owner()})
    return bzx


def deployIToken(bzx, underlyingToken, acct, LoanTokenLogicStandard, LoanToken, loanTokenSettings, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGESTRY, LoanTokenSettingsLowerAdmin):
    underlyingSymbol = underlyingToken.symbol()
    iTokenSymbol = "i{}v1".format(underlyingSymbol)
    iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
    loanTokenAddress = underlyingToken.address

    loanTokenLogicStandard = LoanTokenLogicStandard.deploy(acct, {'from': acct}).address
    iTokenProxy = LoanToken.deploy(acct, loanTokenLogicStandard, {"from": acct})
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi, acct)

    calldata = loanTokenSettings.initialize.encode_input(loanTokenAddress, iTokenName, iTokenSymbol)
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})

    calldata = loanTokenSettings.setLowerAdminValues.encode_input(
        "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80", # polygon guardian multisig
        "0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C"  # LoanTokenSettingsLowerAdmin contract
    )
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})
    bzx.setLoanPool([iToken], [loanTokenAddress], {"from": acct})
    bzx.setSupportedTokens([loanTokenAddress], [True], True, {"from": acct})

    marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGESTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin)
    return iToken



def marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGESTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin):
    base_data = [
        b"0x0",  # id
        False,  # active
        str(acct),  # owner
        "0x0000000000000000000000000000000000000001",  # loanToken
        "0x0000000000000000000000000000000000000002",  # collateralToken
        Wei("20 ether"),  # minInitialMargin
        Wei("15 ether"),  # maintenanceMargin
        0  # fixedLoanTerm
    ]

    params = []

    supportedTokenAssetsPairs = REGESTRY.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100
    loanTokensArr = []
    collateralTokensArr = []
    amountsArr = []
    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
    for tokenAssetPairA in supportedTokenAssetsPairs:
        params.clear()
        loanTokensArr.clear()
        collateralTokensArr.clear()
        amountsArr.clear()

        # below is to allow new iToken.loanTokenAddress in other existing iTokens
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
        print("itoken", existingIToken.name(), tokenAssetPairA[0])

        ## only USDT
        if existingITokenLoanTokenAddress != underlyingToken.address:
            continue

        for tokenAssetPairB in supportedTokenAssetsPairs:
            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            base_data_copy = base_data.copy()
            base_data_copy[3] = existingITokenLoanTokenAddress
            base_data_copy[4] = collateralTokenAddress # pair is iToken, Underlying
            base_data_copy[5] = "6666666666666666666"  # minInitialMargin
            base_data_copy[6] = Wei("5 ether")  # maintenanceMargin
            params.append(base_data_copy)
            loanTokensArr.append(existingITokenLoanTokenAddress)
            collateralTokensArr.append(collateralTokenAddress)
            amountsArr.append(7*10**18)

        print(params)
        if (len(params) != 0):
            ## Torque loans
            calldata = LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setupLoanParams.encode_input(params, True)
            existingIToken.updateSettings(LOAN_TOKEN_SETTINGS_LOWER_ADMIN.address, calldata, {"from": acct})

            ## Margin trades
            calldata = LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setupLoanParams.encode_input(params, False)
            existingIToken.updateSettings(LOAN_TOKEN_SETTINGS_LOWER_ADMIN.address, calldata, {"from": acct})

        bzx.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": acct})
        existingIToken.updateSettings(
            loanTokenSettingsLowerAdmin.address,
            loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(0, 20*10**18, 0, 0, 60*10**18, 80*10**18, 120*10**18),
             {"from": acct}
        )
@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xc2132D05D31c914a87C6611C10748AEb04B58e8F", abi=TestToken.abi)

@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDT", address="0x5BFAC8a40782398fb662A69bac8a89e6EDc574b1", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iUSDTv1(accounts, USDT, LoanTokenLogicStandard,LoanToken, BZX, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGESTRY, LoanTokenSettingsLowerAdmin):
    acct = BZX.owner()
    return deployIToken(BZX, USDT, acct, LoanTokenLogicStandard, LoanToken, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGESTRY, LoanTokenSettingsLowerAdmin)




@pytest.fixture(scope="module")
def REGESTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGESTRY", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765",
                             abi=TokenRegistry.abi, owner=accounts[0])


def test_InterestRate_1(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    amount = 100e18
    USDT.transfer(accounts[0], 1000e6, {'from': iUSDT})
    USDT.approve(iUSDTv1, 2**256-1, {'from': accounts[0]})
    USDT.approve(BZX, 2**256-1, {'from': accounts[0]})
    borrowAmount = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"

    assert False
    iUSDTv1.mint(accounts[0], 10e6, {'from': accounts[0]})
    txBorrow = iUSDTv1.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress, accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})


    assert False

