#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts, chain
from brownie.convert.datatypes import  Wei
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import json

@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS_LOWER_ADMIN(LoanTokenSettingsLowerAdmin):
    return  Contract.from_abi("loanTokenSettingsLowerAdmin", address="0x11F58881D46BcfbB4E4c83F65de401eAd80ecF06", abi=LoanTokenSettingsLowerAdmin.abi)



@pytest.fixture(scope="module")
def LOAN_TOKEN_SETTINGS(accounts, interface, LoanTokenSettings):
    #return Contract.from_abi("loanToken", address="0x3ff9BFe18206f81d073e35072b1c4D61f866663f", abi=LoanTokenSettings.abi)

    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB",
                            abi=interface.IBZx.abi, owner=accounts[0])
    return LoanTokenSettings.deploy({'from': bzx.owner()})



@pytest.fixture(scope="module")
def CUI(CurvedInterestRate, accounts):
    return accounts[0].deploy(CurvedInterestRate)

@pytest.fixture(scope="module")
def BZX(accounts, interface, ProtocolSettings, LoanSettings, LoanOpenings, LoanMaintenance_Arbitrum, LoanMaintenance_2, LoanClosings_Arbitrum, SwapsExternal, SwapsImplUniswapV2_ARBITRUM, DexRecords, SwapsImplUniswapV3_ETH):
    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB",abi=interface.IBZx.abi, owner=accounts[0])


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
    loanMaintenance = LoanMaintenance_Arbitrum.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance.address, {'from': bzx.owner()})

    ## LoanClosings
    print("Deploying LoanClosings.")
    loanClosings = LoanClosings_Arbitrum.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(loanClosings.address, {'from': bzx.owner()})

    ## SwapsExternal
    print("Deploying SwapsExternal.")
    swapsExternal = SwapsExternal.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(swapsExternal.address, {'from': bzx.owner()})

    print("Deploying Protocol Settings")
    protocolSettings = ProtocolSettings.deploy({'from': bzx.owner()})
    print("Calling replaceContract.")
    bzx.replaceContract(protocolSettings.address, {'from': bzx.owner()})
    
    print("Deploying Dex Selector and Implementations")
    dex_record = DexRecords.deploy({'from':bzx.owner()})
    univ2_arbitrum = SwapsImplUniswapV2_ARBITRUM.deploy({'from':bzx.owner()})
    univ3 = SwapsImplUniswapV3_ETH.deploy({'from':bzx.owner()})
    dex_record.setDexID(univ2_arbitrum.address, {'from':bzx.owner()})
    dex_record.setDexID(univ3.address, {'from':bzx.owner()})
    bzx.setSwapsImplContract(dex_record.address, {'from':bzx.owner()})

    return bzx


def replaceIToken(bzx, iTokenProxy,underlyingToken, acct, LoanTokenLogicStandard, LoanToken,
                  LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, CUI):
    loanTokenLogicStandard = LoanTokenLogicStandard.deploy(acct, {'from': acct}).address
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': bzx.owner()})
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi, acct)
    marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin)
    return iToken


def deployIToken(bzx, underlyingToken, acct, LoanTokenLogicStandard, LoanToken, loanTokenSettings, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, accounts, CUI):
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
        "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2", # polygon guardian multisig
        "0x11F58881D46BcfbB4E4c83F65de401eAd80ecF06"  # LoanTokenSettingsLowerAdmin contract
    )
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})
    bzx.setLoanPool([iToken], [loanTokenAddress], {"from": acct})
    bzx.setSupportedTokens([loanTokenAddress], [True], True, {"from": acct})

    marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin, accounts, CUI)
    return iToken


def marginSettings(bzx, underlyingToken, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, acct, LoanTokenLogicStandard, LoanTokenSettingsLowerAdmin, accounts,CUI):
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
        "loanToken", address="0x11F58881D46BcfbB4E4c83F65de401eAd80ecF06", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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

        loanTokenSettingsLowerAdmin = accounts[0].deploy(LoanTokenSettingsLowerAdmin)
        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(CUI)

        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata,{"from": existingIToken.owner()})
@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", abi=TestToken.abi)

@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0x82af49447d8a07e3bd95bd0d56f35241523fbab1", abi=TestToken.abi)

@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDT", address="0xd103a2D544fC02481795b0B33eb21DE430f3eD23", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def iUSDTv1(accounts, USDT, iUSDT, LoanTokenLogicStandard,LoanToken, BZX, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, CUI, WETH):
    acct = BZX.owner()

    itoken = deployIToken(BZX, USDT, acct, LoanTokenLogicStandard, LoanToken, LOAN_TOKEN_SETTINGS, LOAN_TOKEN_SETTINGS_LOWER_ADMIN, REGISTRY, LoanTokenSettingsLowerAdmin, accounts, CUI)
    USDT.approve(BZX, 2**256-1, {'from': itoken})
    for i in range(0,9):
        USDT.approve(itoken, 2**256-1, {'from': accounts[i]})
        USDT.transfer(accounts[i], 1000e6, {'from': "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3"})
        USDT.approve(BZX, 2**256-1, {'from': accounts[i]})
        WETH.approve(itoken, 2**256-1, {'from': accounts[i]})
        WETH.transfer(accounts[i], 100e18, {'from': "0x74c764d41b77dbbb4fe771dab1939b00b146894a"})
        WETH.approve(BZX, 2**256-1, {'from': accounts[i]})
    return itoken




@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x86003099131d83944d826F8016E09CC678789A30",
                             abi=TokenRegistry.abi, owner=accounts[0])

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass

def test_0(requireFork, iUSDTv1, USDT, iUSDT, accounts, BZX):

    amount = 100e18
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
    loanId =  BZX.getUserLoans(accounts[0], 0,20,0, 0,0)[0][0]

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

    assert True


def _base(iToken, token, BZX, acct0,acct1, acct2, CUI):
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 10e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    balance1 = token.balanceOf(acct0)
    iToken.mint(acct0, 100e6, {'from': acct0})
    chain.mine()
    #12%
    txBorrow = iToken.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount)})
    loanId1 =  BZX.getUserLoans(acct1, 0,20,0, 0,0)[0][0]

    tokenPrice1 = iToken.tokenPrice()/1e18
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iToken.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    for i in range(0,9):
        iToken.borrow("", 1e6, borrowTime, 1e18, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(1e18)})

    percent1 = BZX.getInterestModelValues(iToken, loanId1)[4]/1e18

    chain.mine(timedelta=60*60*24*365)
    ratio = (BZX.getInterestModelValues(iToken, loanId1)[4]/1e18)/((BZX.getLoanPrincipal(loanId1)-10e6)*100/10e6)
    assert ratio > 0.99 and ratio < 1.01

    collateralAmount = 1e18
    borrowAmount2 = 1e6
    txBorrow = iToken.borrow("", borrowAmount2, borrowTime, collateralAmount, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount)})
    loanId2 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0][0]
    for i in range(0,9):
        iToken.mint(acct0, 10e6, {'from': acct0})

    assert borrowAmount2<=BZX.getLoanPrincipal(loanId2)
    chain.mine(timedelta=60*60*24*365)
    percent2 = ((BZX.getLoanPrincipal(loanId2)-1e6)*100/1e6)

    ratio = 10*(((percent1+percent2)/100)+1)/((BZX.getLoanPrincipal(loanId1))/1e6)
    assert ratio > 0.99 and ratio < 1.01


    txBorrow = iToken.borrow("", borrowAmount2, borrowTime, collateralAmount, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount)})
    loanId3 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0][0]
    for i in range(0,9):
        iToken.mint(acct0, 10e6, {'from': acct0})

    assert borrowAmount2<=BZX.getLoanPrincipal(loanId3)
    chain.mine(timedelta=60*60*24*365)
    percent3 = ((BZX.getLoanPrincipal(loanId3)-1e6)*100/1e6)

    ratio = 10*(((percent1+percent2+percent3)/100)+1)/((BZX.getLoanPrincipal(loanId1))/1e6)
    assert ratio > 0.99 and ratio < 1.01

    for loan in BZX.getUserLoans(acct2, 0,30,0, 0,0):
        BZX.closeWithDeposit(loan[0], acct2, BZX.getLoanPrincipal(loan[0])+100000, {'from': acct2})
    for loan in BZX.getUserLoans(acct1, 0,30,0, 0,0):
        BZX.closeWithDeposit(loan[0], acct1, BZX.getLoanPrincipal(loan[0])+100000, {'from': acct1})

    tokenPrice2 =  iToken.tokenPrice()/1e18

    assert tokenPrice2 > tokenPrice1

    balance1 = token.balanceOf(acct0)
    burnAmount = iToken.balanceOf(acct0) * 0.999
    balance1 = token.balanceOf(acct0)
    iToken.burn(acct0, burnAmount, {'from': acct0})
    balance2 = token.balanceOf(acct0)
    assert int((balance2-balance1)/1e6) == int(burnAmount/1e6 * iToken.tokenPrice()/1e18)
    assert int(tokenPrice2) == int(iToken.tokenPrice()/1e18)
    assert True


def test_InterestRate_1(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX, CUI):
    acct0 = accounts[4]
    acct1 = accounts[5]
    acct2 = accounts[4]
    _base(iUSDTv1, USDT, BZX, acct0,acct1, acct2, CUI)


def test_trade(requireFork, USDT, iUSDTv1, accounts, BZX, WETH,CUI):
    acct0 = accounts[4]
    acct1 = accounts[1]
    acct2 = accounts[2]
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 0.01e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(acct0, 150e6, {'from': acct0})
    chain.mine()
    iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*4)})

    iUSDTv1.marginTrade('0x0000000000000000000000000000000000000000000000000000000000000000', 3e18, 0, collateralAmount/2, collateralAddress, acct2, b'',{'from': acct2,  'value': Wei(collateralAmount/2)})
    loan1 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0]

    #iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*4)})
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    for i in range(0,6):
        iUSDTv1.borrow("", borrowAmount1/10, borrowTime, collateralAmount/10, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount/10)})
    chain.mine(timedelta=60*60*24*365)
    BZX.getLoanPrincipal(loan1[0]) == loan1[4]+ BZX.getLoanInterestOutstanding(loan1[0])

    balanceBefore = WETH.balanceOf(acct2)
    usdBalanceBefore = USDT.balanceOf(acct2)
    principal = BZX.getLoanPrincipal(loan1[0])
    BZX.closeWithDeposit(loan1[0], acct2, principal+1000, {'from': acct2})

    assert balanceBefore + loan1[5] == WETH.balanceOf(acct2)
    assert (usdBalanceBefore - principal) / USDT.balanceOf(acct2) > 0.999
    assert len(BZX.getUserLoans(acct2, 0,20,0, 0,1)) == 0

    route = encode_abi_packed(['address','uint24','address'],["0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",500,"0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"])
    swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,chain.time()+10000,100,100)]])
    data_provided = encode_abi(['uint256','bytes'],[2,swap_payload])
    sendOut = encode_abi(['uint128','bytes[]'],[2,[data_provided]]) #flag value of Base-2: 10
    iUSDTv1.marginTrade('0x0000000000000000000000000000000000000000000000000000000000000000', 3e18, 0, collateralAmount/2, collateralAddress, acct2, sendOut.hex(),{'from': acct2,  'value': Wei(collateralAmount/2)})
    assert True

def test_liquidate(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX, WETH):
    acct0 = accounts[4]
    acct1 = accounts[1]
    acct2 = accounts[2]
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 0.01e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(acct0, 150e6, {'from': acct0})
    chain.mine()
    iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*4)})
    loan1 = BZX.getUserLoans(acct1, 0,20,0, 0,0)[0]
    iUSDTv1.marginTrade('0x0000000000000000000000000000000000000000000000000000000000000000', 3e18, 0, collateralAmount/2, collateralAddress, acct2, b'',{'from': acct2,  'value': Wei(collateralAmount/2)})
    loan2 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0]

    #iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*4)})
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    for i in range(0,6):
        iUSDTv1.borrow("", borrowAmount1/10, borrowTime, collateralAmount/10, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount/10)})
    chain.mine(timedelta=60*60*24*365*5)
    l1 = len(BZX.getUserLoans(acct1, 0,20,0, 0,1))
    l2 = len(BZX.getUserLoans(acct2, 0,20,0, 0,1))
    balanceBefore = WETH.balanceOf(acct0)
    BZX.liquidate(loan1[0], acct0, BZX.getLoanPrincipal(loan1[0])+1000, {'from': acct0})
    BZX.liquidate(loan2[0], acct0, BZX.getLoanPrincipal(loan2[0])+1000, {'from': acct0})
    assert len(BZX.getUserLoans(acct1, 0,20,0, 0,1)) == l1 - 1
    assert len(BZX.getUserLoans(acct2, 0,20,0, 0,1)) == l2 - 1
    assert WETH.balanceOf(acct0) == balanceBefore + loan1[5] + loan2[5]
    assert True


def test_borrowmore(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    acct0 = accounts[4]
    acct1 = accounts[1]
    acct2 = accounts[2]
    borrowAmount1 = 10e6
    borrowTime = 7884000
    collateralAmount = 0.01e18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    iUSDTv1.mint(acct0, 150e6, {'from': acct0})
    chain.mine()
    iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount*4)})
    iUSDTv1.borrow("", borrowAmount1*4, borrowTime, collateralAmount*4, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount*4)})

    loan1 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0]
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    iUSDTv1.borrow("", borrowAmount1*2, borrowTime, collateralAmount*2, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount*2)})
    for i in range(0,4):
        iUSDTv1.borrow("", borrowAmount1/10, borrowTime, collateralAmount/10, collateralAddress, acct1, acct1, b"", {'from': acct1, 'value': Wei(collateralAmount/10)})

    loan1 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0]
    chain.mine(timedelta=60*60*24*365)
    interestRate1 = ((BZX.getLoanPrincipal(loan1[0])-loan1[4])*100/loan1[4])
    iUSDTv1.borrow("", borrowAmount1, borrowTime, collateralAmount, collateralAddress, acct2, acct2, b"", {'from': acct2, 'value': Wei(collateralAmount)})
    loan2 = BZX.getUserLoans(acct2, 0,20,0, 0,0)[0]
    chain.mine(timedelta=60*60*24*365)
    interestRate2 = ((BZX.getLoanPrincipal(loan2[0])-loan2[4])*100/loan2[4])
    assert int(((BZX.getLoanPrincipal(loan1[0])/loan1[4])-1) * 1000) == int((interestRate1 + interestRate2)/100 * 1000)
    assert True


def test_token_price(requireFork, iUSDTv1, USDT,iUSDT, accounts, BZX):
    # assert False
    acct0 = accounts[4]
    acct1 = accounts[5]
    iUSDTv1.mint(acct1, 0.001e6, {'from': acct1})

    iUSDTv1.mint(acct0, 100e6, {'from': acct0})

    assert int(iUSDTv1.balanceOf(acct0)/1e6) == 100

    USDT.transfer(iUSDTv1, 50e6, {'from': acct1})

    assert int(iUSDTv1.tokenPrice()/1e16) == 149
    balanceBefore = int(iUSDTv1.balanceOf(acct0)/1e6)
    iUSDTv1.mint(acct0, 100e6, {'from': acct0})

    assert int(iUSDTv1.balanceOf(acct0)/1e6) ==balanceBefore + int(100/(iUSDTv1.tokenPrice()/1e18))

    USDT.transfer(iUSDTv1, 100e6, {'from': acct1})

    assert int(iUSDTv1.tokenPrice()/1e16) > 200 # 209

    balanceBeforeIUSDT = iUSDTv1.balanceOf(acct0)
    balanceBeforeUSDT = USDT.balanceOf(acct0)

    # burning here 166 iUSDT at token price 2.09 166* 2.09= 346.94
    expecetedAmount = balanceBeforeIUSDT * iUSDTv1.tokenPrice() / 1e18
    iUSDTv1.burn(acct0, balanceBeforeIUSDT, {"from": acct0})
    actualAmount = USDT.balanceOf(acct0) - balanceBeforeUSDT

    assert  int((expecetedAmount/1e6)) == int(actualAmount/1e6)
    return True
