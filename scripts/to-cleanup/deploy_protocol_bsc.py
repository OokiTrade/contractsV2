#!/usr/bin/python3

from brownie import *
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

import shared

def main():
    deployProtocol()

def deployProtocol():
    global deploys, bzx, tokens, constants, addresses, thisNetwork, acct

    acct = accounts.load('fresh_deployer1')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    ### DEPLOYMENT START ###

    print("Deploying bZxProtocol.")
    bzxproxy = acct.deploy(bZxProtocol)
    #bzx = Contract.from_abi("bzx", address="0xC47812857A74425e2039b57891a3DFcF51602d5d", abi=interface.IBZx.abi, owner=acct)
    bzx = Contract.from_abi("bzx", address=bzxproxy.address, abi=interface.IBZx.abi, owner=acct)
    #_add_contract(bzx)

    ## PriceFeeds
    print("Deploying PriceFeeds.")
    #feeds = acct.deploy(PriceFeeds_BSC)
    feeds = Contract.from_abi("feeds", address="0x43CCac29802332e1fd3A41264dDbe34cE3073a88", abi=PriceFeeds.abi, owner=acct)

    '''
    print("Calling setDecimals.")
    feeds.setDecimals(
        [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
            "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
            "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
            "0x55d398326f99059ff775485246999027b3197955", # USDT
            "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
            #"0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            #"0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", # CAKE
            #"0xa184088a740c695E156F91f5cC086a06bb78b827", # AUTO
            #"0xbA2aE424d960c26247Dd6c32edC70B295c744C43", # DOGE
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ]
    , {"from": acct})

    print("Calling setPriceFeed.")
    feeds.setPriceFeed(
        [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
            "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
            "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
            "0x55d398326f99059ff775485246999027b3197955", # USDT
            "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
            #"0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            #"0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", # CAKE
            #"0xa184088a740c695E156F91f5cC086a06bb78b827", # AUTO
            #"0xbA2aE424d960c26247Dd6c32edC70B295c744C43", # DOGE
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ],
        [
            "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE", # BNB
            "0xcBb98864Ef56E9042e7d2efef76141f15731B82f", # BUSD
            "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e", # ETH
            "0xB97Ad0E74fa7d920791E90258A6E2085088b4320", # USDT
            "0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf", # BTC
            #"0xFc362828930519f236ad0c8f126B7996562a695A", # BZRX
            "0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8", # LINK
            #"0xB6064eD41d4f67e353768aA239cA86f4F73665a1", # CAKE
            #"0x88E71E6520E5aC75f5338F5F0c9DeD9d4f692cDA", # AUTO
            #"0x3AB0A0d137D4F946fBB19eecc6e92E64660231C8", # DOGE
            #"0x51597f405303C4377E36123cBc172b13269EA163", # USDC
            #"0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA", # DAI
        ]
    , {"from": acct})
    '''

    ## SwapImpl
    print("Deploying Swaps.")
    #swaps = acct.deploy(SwapsImplUniswapV2_BSC)
    swaps = Contract.from_abi("feeds", address="0x6cb2adf7adb4efce3b10ce8933d8a8d70dba7f78", abi=SwapsImplUniswapV2_BSC.abi, owner=acct)

    ## ProtocolSettings
    print("Deploying ProtocolSettings.")
    settings = acct.deploy(ProtocolSettings)
    print("Calling replaceContract.")
    bzx.replaceContract(settings.address)

    print("Calling setPriceFeedContract.")
    bzx.setPriceFeedContract(
        feeds.address # priceFeeds
    )

    print("Calling setSwapsImplContract.")
    bzx.setSwapsImplContract(
        swaps.address  # swapsImpl
    )

    '''print("Calling setLoanPool.")
    bzx.setLoanPool(
        [
            "", # iBNB
            "", # iBUSD
            "", # iETH
            "", # iUSDT
            "", # iBTC
            "", # iBZRX
            "", # CAKE
            "", # AUTO
            "", # DOGE
            #"", # iLINK
            #"", # iUSDC
            #"", # iDAI
        ],
        [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
            "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
            "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
            "0x55d398326f99059ff775485246999027b3197955", # USDT
            "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
            "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", # CAKE
            "0xa184088a740c695E156F91f5cC086a06bb78b827", # AUTO
            "0xbA2aE424d960c26247Dd6c32edC70B295c744C43", # DOGE
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ]
    , {"from": acct})'''

    print("Calling setSupportedTokens.")
    bzx.setSupportedTokens(
        [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
            "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
            "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
            "0x55d398326f99059ff775485246999027b3197955", # USDT
            "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
            #"0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            #"0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", # CAKE
            #"0xa184088a740c695E156F91f5cC086a06bb78b827", # AUTO
            #"0xbA2aE424d960c26247Dd6c32edC70B295c744C43", # DOGE
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ],
        [
            True, # BNB
            True, # BUSD
            True, # ETH
            True, # USDT
            True, # BTC
            #True, # BZRX
            True, # LINK
            #True, # CAKE
            #True, # AUTO
            #True, # DOGE
            #True, # USDC
            #True, # DAI
        ],
        True
    , {"from": acct})

    ## 7e18 = 5% collateral discount
    # handled in setup_pool_params2
    '''function setLiquidationIncentivePercent(
        address[] calldata loanTokens,
        address[] calldata collateralTokens,
        uint256[] calldata amounts)
        external
        onlyOwner'''

    bzx.setFeesController("0x5c9b515f05a0e2a9b14c171e2675ddc1655d9a1c")

    ## LoanSettings
    print("Deploying LoanSettings.")
    loanSettings = acct.deploy(LoanSettings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanSettings.address)

    ## LoanOpenings
    print("Deploying LoanOpenings.")
    loanOpenings = acct.deploy(LoanOpenings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanOpenings.address)

    ## LoanMaintenance
    print("Deploying LoanMaintenance.")
    loanMaintenance = acct.deploy(LoanMaintenance)
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance.address)

    ## LoanClosings
    print("Deploying LoanClosings.")
    loanClosings = acct.deploy(LoanClosings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanClosings.address)

    ## SwapsExternal
    print("Deploying SwapsExternal.")
    swapsExternal = acct.deploy(SwapsExternal)
    print("Calling replaceContract.")
    bzx.replaceContract(swapsExternal.address)

    ## ProtocolPausableGuardian
    print("Deploying ProtocolPausableGuardian.")
    protocolPausableGuardian = acct.deploy(ProtocolPausableGuardian)
    print("Calling replaceContract.")
    bzx.replaceContract(protocolPausableGuardian)

    bzx.changeGuardian("0x82cedB275BF513447300f670708915F99f085FD6")  # bsc guardian multisig
