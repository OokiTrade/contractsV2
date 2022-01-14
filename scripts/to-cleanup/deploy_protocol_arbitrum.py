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
    #bzx = acct.deploy(bZxProtocol)
    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=interface.IBZx.abi, owner=acct)
    #_add_contract(bzx)

    ## PriceFeeds
    print("Deploying PriceFeeds.")
    feeds = acct.deploy(PriceFeeds_ARBITRUM)
    #feeds = Contract.from_abi("feeds", address=bzx.priceFeeds(), abi=PriceFeeds_ARBITRUM.abi, owner=acct)
    #feeds = Contract.from_abi("feeds", address="0x8f6A694fe9d99F4913501e6592438598DA415C9e", abi=PriceFeeds_ARBITRUM.abi, owner=acct)
    '''
tokens ->
ETH: 0x82af49447d8a07e3bd95bd0d56f35241523fbab1
BTC: 0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f
SPELL: 0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af
LINK: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4

USDC: 0xff970a61a04b1ca14834a43f5de4533ebddb5cc8
USDT: 0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9
MIM: 0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a
FRAX: 0x17fc002b466eec40dae837fc4be5c67993ddbd6f

feeds ->
ETH: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
BTC: 0x6ce185860a4963106506C203335A2910413708e9
SPELL: 0x383b3624478124697BEF675F07cA37570b73992f
LINK: 0x86E53CF1B870786351Da77A57575e79CB55812CB

USDC: 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3
USDT: 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7
MIM: 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b
FRAX: 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8
    '''

    print("Calling setDecimals.")
    feeds.setDecimals(
        [
            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", # ETH
            "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", # BTC
            "0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af", # SPELL
            "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4", # LINK
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX
        ]
    , {"from": acct})

    print("Calling setPriceFeed.")
    feeds.setPriceFeed(
        [
            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", # ETH
            "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", # BTC
            "0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af", # SPELL
            "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4", # LINK
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX
        ],
        [
            "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612", # ETH
            "0x6ce185860a4963106506C203335A2910413708e9", # BTC
            "0x383b3624478124697BEF675F07cA37570b73992f", # SPELL
            "0x86E53CF1B870786351Da77A57575e79CB55812CB", # LINK
            "0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3", # USDC
            "0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7", # USDT
            "0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b", # MIM
            "0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8", # FRAX
        ]
    , {"from": acct})


    ## SwapImpl
    print("Deploying Swaps.")
    swaps = acct.deploy(SwapsImplUniswapV2_ARBITRUM)
    #swaps = Contract.from_abi("swaps", address="0xa9033952ac045168243a1a50c889516445247618", abi=SwapsImplUniswapV2_ARBITRUM.abi, owner=acct)

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
            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", # ETH
            "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", # BTC
            "0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af", # SPELL
            "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4", # LINK
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX
        ],
        [
            "", # ETH
            "", # MIM
            "", # SPELL
            "", # USDC
            "", # BTC
        ]
    , {"from": acct})'''

    print("Calling setSupportedTokens.")
    bzx.setSupportedTokens(
        [
            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", # ETH
            "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", # BTC
            "0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af", # SPELL
            "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4", # LINK
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX
        ],
        [
            True, # ETH
            True, # BTC
            True, # SPELL
            True, # LINK
            True, # USDC
            True, # USDT
            True, # MIM
            True, # FRAX
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

    bzx.setFeesController("0x111F9F3e59e44e257b24C5d1De57E05c380C07D2")

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
    loanMaintenance = acct.deploy(LoanMaintenance_Arbitrum)
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance.address)

    ## LoanMaintenance_2
    print("Deploying LoanMaintenance_2.")
    loanMaintenance2 = acct.deploy(LoanMaintenance_2)
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance2.address)

    ## LoanClosings
    print("Deploying LoanClosings.")
    loanClosings = acct.deploy(LoanClosings_Arbitrum)
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

    bzx.changeGuardian("0x111F9F3e59e44e257b24C5d1De57E05c380C07D2")  # arbitrum guardian multisig
