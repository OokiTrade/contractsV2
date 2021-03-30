#!/usr/bin/python3

from brownie import *
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

import shared

def main():
    deployProtocol()

def deployProtocol():
    global deploys, bzx, tokens, constants, addresses, thisNetwork, acct

    acct = accounts.load('deployer1')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    ### DEPLOYMENT START ###

    print("Deploying bZxProtocol.")
    #bzxproxy = acct.deploy(bZxProtocol)
    bzx = Contract.from_abi("bzx", address="0xC47812857A74425e2039b57891a3DFcF51602d5d", abi=interface.IBZx.abi, owner=acct)
    _add_contract(bzx)

    ## PriceFeeds
    print("Deploying PriceFeeds.")
    feeds = acct.deploy(PriceFeeds_BSC)
    #feeds = Contract.from_abi("feeds", address=bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)

    print("Calling setDecimals.")
    feeds.setDecimals(
        [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
            "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
            "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
            "0x55d398326f99059ff775485246999027b3197955", # USDT
            "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
            "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            #"0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
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
            "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            #"0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ],
        [
            "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE", # BNB
            "0xcBb98864Ef56E9042e7d2efef76141f15731B82f", # BUSD
            "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e", # ETH
            "0xB97Ad0E74fa7d920791E90258A6E2085088b4320", # USDT
            "0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf", # BTC
            "0xFc362828930519f236ad0c8f126B7996562a695A", # BZRX
            #"0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8", # LINK
            #"0x51597f405303C4377E36123cBc172b13269EA163", # USDC
            #"0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA", # DAI
        ]
    , {"from": acct})


    ## SwapImpl
    print("Deploying Swaps.")
    swaps = acct.deploy(SwapsImplUniswapV2_BSC)

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
            #"0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
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
            "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
            #"0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
            #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
            #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
        ],
        [
            True, # BNB
            True, # BUSD
            True, # ETH
            True, # USDT
            True, # BTC
            True, # BZRX
            #True, # LINK
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

    bzx.setFeesController(acct.address)

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
