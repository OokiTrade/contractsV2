#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts, chain
from brownie.convert.datatypes import  Wei
import json

@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS_LOWER_ADMIN(LoanTokenSettingsLowerAdmin):
    return  Contract.from_abi("loanTokenSettingsLowerAdmin", address="0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C", abi=LoanTokenSettingsLowerAdmin.abi)



@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS(accounts, interface, LoanTokenSettings):
    #return Contract.from_abi("loanToken", address="0x3ff9BFe18206f81d073e35072b1c4D61f866663f", abi=LoanTokenSettings.abi)

    bzx = Contract.from_abi("bzx", address="0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8",
                            abi=interface.IBZx.abi, owner=accounts[0])
    return LoanTokenSettings.deploy({'from': bzx.owner()})


@pytest.fixture(scope="module")
def BZX(accounts, interface, LoanSettings, LoanOpenings, LoanMaintenance_2, LoanMaintenance, LoanClosings):
    bzx = Contract.from_abi("bzx", address="0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8",abi=interface.IBZx.abi, owner=accounts[0])


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


def replaceIToken(bzx, iTokenProxy,underlyingToken, acct, LoanTokenLogicStandard, LoanToken,
                  LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin):
    loanTokenLogicStandard = LoanTokenLogicStandard.deploy(acct, {'from': acct}).address
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': bzx.owner()})
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi, acct)
    marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin)
    return iToken


def deployIToken(bzx, underlyingToken, acct, LoanTokenLogicStandard, LoanToken, loanTokenSettings, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, accounts, CurvedInterestRate):
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

    marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin, accounts, CurvedInterestRate)
    return iToken



def marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin, accounts,CurvedInterestRate):
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

    supportedTokenAssetsPairs = REGISTRY.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100
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
        cui = accounts[0].deploy(CurvedInterestRate)
        loanTokenSettingsLowerAdmin = accounts[0].deploy(LoanTokenSettingsLowerAdmin)
        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(cui)

        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata,{"from": existingIToken.owner()})
@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xc2132D05D31c914a87C6611C10748AEb04B58e8F", abi=TestToken.abi)

@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDT", address="0x5BFAC8a40782398fb662A69bac8a89e6EDc574b1", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iUSDTv1(accounts, USDT, iUSDT, LoanTokenLogicStandard,LoanToken, BZX, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, CurvedInterestRate):
    acct = BZX.owner()

    itoken = deployIToken(BZX, USDT, acct, LoanTokenLogicStandard, LoanToken, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, accounts, CurvedInterestRate)
    USDT.approve(BZX, 2**256-1, {'from': itoken})
    USDT.approve(itoken, 2**256-1, {'from': accounts[0]})
    USDT.approve(itoken, 2**256-1, {'from': accounts[1]})
    USDT.approve(itoken, 2**256-1, {'from': accounts[2]})
    USDT.approve(itoken, 2**256-1, {'from': accounts[4]})
    USDT.approve(itoken, 2**256-1, {'from': accounts[9]})

    USDT.transfer(accounts[0], 1000e6, {'from': iUSDT})
    USDT.transfer(accounts[1], 1000e6, {'from': iUSDT})
    USDT.transfer(accounts[2], 1000e6, {'from': iUSDT})
    USDT.transfer(accounts[4], 1000e6, {'from': iUSDT})
    USDT.transfer(accounts[9], 1000e6, {'from': iUSDT})
    USDT.approve(BZX, 2**256-1, {'from': accounts[0]})
    USDT.approve(BZX, 2**256-1, {'from': accounts[1]})
    USDT.approve(BZX, 2**256-1, {'from': accounts[2]})
    USDT.approve(BZX, 2**256-1, {'from': accounts[4]})
    USDT.approve(BZX, 2**256-1, {'from': accounts[9]})
    #itoken.mint(accounts[9], 100e6, {'from':  accounts[9]})
    return itoken




@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765",
                             abi=TokenRegistry.abi, owner=accounts[0])



@pytest.fixture(scope="module")
def USDC(accounts, TestToken, BZX):
    usdc = Contract.from_abi("USDC", address="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", abi=TestToken.abi)
    return usdc

@pytest.fixture(scope="module")
def iUSDC(accounts, USDC, LoanTokenLogicStandard,LoanToken, BZX, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin):
    acct = BZX.owner()
    iTokenProxy = Contract.from_abi("iUSDC", address="0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d", abi=LoanToken.abi)
    itoken = replaceIToken(BZX, iTokenProxy, USDC, acct, LoanTokenLogicStandard, LoanToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin)
    USDC.approve(itoken, 2**256-1, {'from': accounts[0]})
    USDC.approve(itoken, 2**256-1, {'from': accounts[1]})
    USDC.approve(itoken, 2**256-1, {'from': accounts[2]})
    USDC.approve(itoken, 2**256-1, {'from': accounts[9]})
    USDC.transfer(accounts[0], 1000e6, {'from': iTokenProxy})
    USDC.transfer(accounts[1], 1000e6, {'from': iTokenProxy})
    USDC.transfer(accounts[2], 1000e6, {'from': iTokenProxy})
    USDC.transfer(accounts[9], 1000e6, {'from': iTokenProxy})
    USDC.approve(BZX, 2**256-1, {'from': accounts[0]})
    USDC.approve(BZX, 2**256-1, {'from': accounts[1]})
    USDC.approve(BZX, 2**256-1, {'from': accounts[2]})
    USDC.approve(BZX, 2**256-1, {'from': accounts[9]})
    #itoken.mint(accounts[9], 100e6, {'from':  accounts[9]})

    return Contract.from_abi("iUSDC", address=iTokenProxy, abi=LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765",
                             abi=TokenRegistry.abi, owner=accounts[0])

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass

def test_0(requireFork, iUSDTv1, USDT, iUSDT, accounts, BZX):
    
    amount = 100e18
    USDT.transfer(accounts[0], 1000e6, {'from': iUSDT})
    USDT.approve(iUSDTv1, 2**251, {'from': accounts[0]})
    USDT.approve(BZX, 2**251, {'from': accounts[0]})
    borrowAmount = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(accounts[0], 1e6, {'from': accounts[0]})
    print(chain.time(),"start - vals",BZX.getInterestModelValues(iUSDTv1.address, 0))
    print(chain.time(),"start - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"start - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"start - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"start - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"start - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"start - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"start - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    iUSDTv1.mint(accounts[0], 100e6, {'from': accounts[0]})

    print(chain.time(),"after mint - vals",BZX.getInterestModelValues(iUSDTv1.address, 0))
    print(chain.time(),"after mint - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after mint - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after mint - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after mint - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after mint - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after mint - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after mint - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    txBorrow = iUSDTv1.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress, accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})
    loanId =  BZX.getUserLoans(accounts[0], 0,10,0, 0,0)[0][0]

    print(chain.time(),"after borrow - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after borrow - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after borrow - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after borrow - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after borrow - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after borrow - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after borrow - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after borrow - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after borrow - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    chain.mine(timedelta=60*60*24*365)

    print(chain.time(),"after 1 year - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after 1 year - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after 1 year - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after 1 year - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after 1 year - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after 1 year - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after 1 year - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after 1 year - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after 1 year - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    iUSDTv1.burn(accounts[0], 87e6, {'from': accounts[0]})

    print(chain.time(),"after burn - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after burn - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after burn - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after burn - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after burn - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after burn - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after burn - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after burn - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after burn - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    chain.mine(timedelta=60*60*24*365)

    print(chain.time(),"after 2 year - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after 2 year - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after 2 year - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after 2 year - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after 2 year - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after 2 year - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after 2 year - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after 2 year - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after 2 year - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    iUSDTv1.mint(accounts[0], 100e6, {'from': accounts[0]})

    print(chain.time(),"after mint - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after mint - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after mint - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after mint - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after mint - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after mint - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after mint - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after mint - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after mint - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    chain.mine(timedelta=60*60*24*365)

    print(chain.time(),"after 3 year - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after 3 year - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after 3 year - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after 3 year - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after 3 year - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after 3 year - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after 3 year - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after 3 year - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after 3 year - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    txClose = BZX.closeWithDeposit(loanId, accounts[0], 3e6, {'from': accounts[0]})

    print(chain.time(),"after partial close - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after partial close - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after partial close - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after partial close - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after partial close - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after partial close - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after partial close - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after partial close - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after partial close - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    chain.mine(timedelta=60*60*24*365)

    print(chain.time(),"after 4 year - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after 4 year - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after 4 year - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after 4 year - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after 4 year - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after 4 year - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after 4 year - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after 4 year - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after 4 year - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    txClose = BZX.closeWithDeposit(loanId, accounts[0], 2**251, {'from': accounts[0]})

    print(chain.time(),"after full close - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after full close - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after full close - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after full close - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after full close - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after full close - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after full close - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after full close - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after full close - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    iUSDTv1.burn(accounts[0], 2**256-1, {'from': accounts[0]})

    print(chain.time(),"after final burn - vals",BZX.getInterestModelValues(iUSDTv1.address, loanId))
    print(chain.time(),"after final burn - borrowInterestRate",iUSDTv1.borrowInterestRate()/1e18)
    print(chain.time(),"after final burn - totalSupply",iUSDTv1.totalSupply()/1e6)
    print(chain.time(),"after final burn - totalAssetSupply",iUSDTv1.totalAssetSupply()/1e6)
    print(chain.time(),"after final burn - totalAssetBorrow",iUSDTv1.totalAssetBorrow()/1e6)
    print(chain.time(),"after final burn - tokenPrice",iUSDTv1.tokenPrice()/1e18)
    print(chain.time(),"after final burn - asset balance",USDT.balanceOf(iUSDTv1)/1e6)
    print(chain.time(),"after final burn - getLoanPrincipal",BZX.getLoanPrincipal(loanId)/1e6)
    print(chain.time(),"after final burn - getTotalPrincipal",BZX.getTotalPrincipal(iUSDTv1.address, iUSDTv1.address)/1e6)

    assert False


def _base(iToken, token, BZX, acct0,acct1, acct2):
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iToken.mint(acct0, 100e6, {'from': acct0})
    chain.mine()
    #12%
    txBorrow = iToken.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    loanId1 =  BZX.getUserLoans(acct1, 0,10,0, 0,0)[0][0]
    chain.mine(timedelta=60*60*24*365)
    assert int((BZX.getLoanPrincipal(loanId1)/borrowAmount1-1)*100) == 12

    collateralAmount = 90e18
    borrowAmount2 = 90e6

    txBorrow = iToken.borrow("", borrowAmount2, borrowTime, collateralAmount, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount)})
    loanId2 =  BZX.getUserLoans(acct2, 0,10,0, 0,0)[0][0]
    assert borrowAmount2<=BZX.getLoanPrincipal(loanId2)
    chain.mine(timedelta=60*60*24*365)
    assert borrowAmount2<BZX.getLoanPrincipal(loanId2)
    assert 120 / int((BZX.getLoanPrincipal(loanId2)/borrowAmount2-1)*100) > 0.99
    assert ((12+120)/2) / (int((BZX.getLoanPrincipal(loanId1)/borrowAmount1-1)*100)/2) > 0.99


    usdtBalance2BeforeClose = token.balanceOf(acct2)
    loanId2Principal = BZX.getLoanPrincipal(loanId2)


def test_InterestRate_1(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    acct0 = accounts[4]
    acct1 = accounts[5]
    iToken = iUSDTv1
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iToken.mint(acct0, 100e6, {'from': acct0})
    chain.mine()
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iToken.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    for i in range(0,9):
        iToken.borrow("", 1e6, borrowTime, 1e18, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(1e18)})
    assert False

def test_InterestRate_2(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    acct0 = accounts[4]
    _base(iUSDTv1, USDT, BZX, acct0,acct0, acct0)


def test_trade(requireFork, USDT, iUSDTv1, accounts, BZX):
    acct0 = accounts[4]
    acct1 = accounts[1]
    acct2 = accounts[2]

    borrowAmount1 = 90e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(acct0, 100e6, {'from': acct0})
    chain.mine()
    iUSDTv1.marginTrade('0x0000000000000000000000000000000000000000000000000000000000000000', 3e18, 0, collateralAmount, '0x0000000000000000000000000000000000000000', acct2, b'',{'from': acct2,  "value": collateralAmount})
    loan = BZX.getUserLoans(acct2, 0,10,0, 0,0)[-1]
    loanPrincipal = loan[4]
    loanId1 =  loan[0]
    chain.mine(timedelta=60*60*24*365*5)
    assert len(BZX.getUserLoans(acct2, 0,10,0, 0,1)) == 1
    BZX.liquidate(loanId1, acct0, 2**256-1, {'from': acct0})
    assert len(BZX.getUserLoans(acct2, 0,10,0, 0,1)) == 0


def test_liquidate(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    acct0 = accounts[4]
    acct1 = accounts[1]
    acct2 = accounts[2]
    borrowAmount1 =  15e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(acct0, 100e6, {'from': acct0})
    txBorrow = iUSDTv1.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    loanId1 =  BZX.getUserLoans(acct1, 0,10,0, 0,0)[0][0]
    chain.mine(timedelta=60*60*24*365*5)
    assert len(BZX.getUserLoans(acct1, 0,10,0, 0,1)) == 1
    loan =  BZX.getUserLoans(acct1, 0,10,0, 0,1)[0]
    BZX.liquidate(loanId1, acct2, loan[-4]+1000, {'from': acct2})
    assert len(BZX.getUserLoans(acct1, 0,10,0, 0,1)) == 0
    iUSDTv1.burn(acct0, iUSDTv1.balanceOf(acct0), {'from': acct0})


def test_borrowmore(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    acct0 = accounts[7]
    acct1 = accounts[5]
    acct2 = accounts[6]
    borrowAmount1 =  15e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    USDT.transfer(acct0, 1000e6, {'from': iUSDT})
    USDT.approve(iUSDTv1, 2**256-1, {'from': acct0})
    iUSDTv1.mint(acct0, 100e6, {'from': acct0})
    interestRate1 =  iUSDTv1.nextBorrowInterestRate(borrowAmount1)
    txBorrow = iUSDTv1.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    loanId1 =  BZX.getUserLoans(acct1, 0,10,0, 0,0)[0][0]
    chain.mine(timedelta=60*60*24*365)
    int((BZX.getLoanPrincipal(loanId1)/borrowAmount1-1)*100) == interestRate1/1e18

    txBorrow = iUSDTv1.borrow("", borrowAmount1*4, borrowTime, acct2.balance(), collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(acct2.balance())})

    interestRate2 =  iUSDTv1.nextBorrowInterestRate(borrowAmount1)
    txBorrow = iUSDTv1.borrow(loanId1, borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    chain.mine(timedelta=60*60*24*365)
    int(((BZX.getLoanPrincipal(loanId1)/(2*borrowAmount1))-1)*100)/2 == int((interestRate1 * borrowAmount1 +interestRate2 * (borrowAmount1*2))/(borrowAmount1*2)/2/1e18)
