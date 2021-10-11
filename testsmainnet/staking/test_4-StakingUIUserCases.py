#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def testStake_UserStory1_StakedFirstTime(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH, ):

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    LPT.transfer(accounts[1], 1e18, { 'from': accounts[9]})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX, LPT]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX, balanceOfLPT]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == balanceOfLPT)

    assert True


def testStake_UserStory2_StakedMoreTokens(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH, ):

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    # LPT.transferFrom("0xe95ebce2b02ee07def5ed6b53289801f7fc137a4", accounts[1], 100e18, {
    #                  'from': "0xe95ebce2b02ee07def5ed6b53289801f7fc137a4"})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    # balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    # LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == 0)

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    # LPT.transferFrom("0xe95ebce2b02ee07def5ed6b53289801f7fc137a4", accounts[1], 100e18, {
    #                  'from': "0xe95ebce2b02ee07def5ed6b53289801f7fc137a4"})

    balanceOfBZRXAfter = BZRX.balanceOf(accounts[1])
    balanceOfvBZRXAfter = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRXAfter = iBZRX.balanceOf(accounts[1])
    # balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRXAfter, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRXAfter, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRXAfter, {'from': accounts[1]})
    # LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRXAfter, balanceOfvBZRXAfter, balanceOfiBZRXAfter]
    tx = stakingV1_1.stake(tokens, amounts,  {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX + balanceOfBZRXAfter) # some has vested
    assert(balances[1] == balanceOfiBZRX + balanceOfiBZRXAfter)
    assert(balances[2] == balanceOfvBZRX + balanceOfvBZRXAfter)
    assert(balances[3] == 0)

    assert True


def testStake_UserStory3_IClaimMyIncentiveRewards(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH,):
    # those extracted from protocol directly not from staking
    assert True


def testStake_UserStory4_IClaimMyStakingRewards(requireMainnetFork, fees_extractor, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, POOL3, accounts, iUSDC, USDC, WETH, ):
    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    # LPT.transferFrom("0xe95ebce2b02ee07def5ed6b53289801f7fc137a4", accounts[1], 100e18, {
    #                  'from': "0xe95ebce2b02ee07def5ed6b53289801f7fc137a4"})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    # balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    # LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == 0)

    # create some fees
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    txSweep = fees_extractor.sweepFees({'from': accounts[9]})

    earnings = stakingV1_1.earned.call(accounts[1])

    assert(earnings[0] > 0)
    assert(earnings[1] > 0)
    assert(earnings[2] > 0)
    assert(earnings[3] > 0)

    stakingV1_1.claim(False, {'from': accounts[1]})

    assert(earnings[0] <= BZRX.balanceOf(accounts[1]))
    assert(earnings[1] <= POOL3.balanceOf(accounts[1]))

    earningsAfterClaim = stakingV1_1.earned.call(accounts[1])

    assert(earningsAfterClaim[0] == 0)
    assert(earningsAfterClaim[1] == 0)
    assert(earningsAfterClaim[2] <= earnings[2])
    assert(earningsAfterClaim[3] <= earnings[3])

    assert True


def testStake_UserStory5_IClaimAndRestakeMyStakingRewards(requireMainnetFork, fees_extractor, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, POOL3, LPT, accounts, iUSDC, USDC, WETH, ):
    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    LPT.transfer(accounts[1], 1e18, { 'from': accounts[9]})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX, LPT]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX, balanceOfLPT]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == balanceOfLPT)

    # create some fees
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    txSweep = fees_extractor.sweepFees({'from': accounts[9]})
    balance = stakingV1_1.balanceOfByAssets.call(accounts[1])
    earnings = stakingV1_1.earned.call(accounts[1])

    assert(earnings[0] > 0)
    assert(earnings[1] > 0)
    assert(earnings[2] > 0)
    assert(earnings[3] > 0)

    stakingV1_1.claim(True, {'from': accounts[1]})

    assert(0 <= BZRX.balanceOf(accounts[1]))
    assert(earnings[1] <= POOL3.balanceOf(accounts[1]))
    balanceAfterClaim = stakingV1_1.balanceOfByAssets.call(accounts[1])
    earningsAfterClaim = stakingV1_1.earned.call(accounts[1])

    assert(earningsAfterClaim[0] == 0)
    assert(earningsAfterClaim[1] == 0)
    assert(earningsAfterClaim[2] <= earnings[2])
    assert(earningsAfterClaim[3] <= earnings[3])

    assert(balanceAfterClaim[0] >= balance[0] + earnings[0])
    assert(balanceAfterClaim[1] == balance[1])
    assert(balanceAfterClaim[2] == balance[2])
    assert(balanceAfterClaim[3] == balance[3])

    assert True


def testStake_IWantToUnstakeMyTokens(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH):

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    LPT.transfer(accounts[1], 1e18, { 'from': accounts[9]})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX, LPT]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX, balanceOfLPT]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])
    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == balanceOfLPT)

    # unstake half
    amounts = [balanceOfBZRX - 10, balanceOfvBZRX - 10, balanceOfiBZRX - 10, balanceOfLPT - 10]
    tx = stakingV1_1.unstake(tokens, amounts, {'from': accounts[1]})

    balanceOfBZRXAfter = BZRX.balanceOf(accounts[1])
    balanceOfvBZRXAfter = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRXAfter = iBZRX.balanceOf(accounts[1])
    balanceOfLPTAfter = LPT.balanceOf(accounts[1])

    stakedBalance = stakingV1_1.balanceOfByAssets(accounts[1])

    assert(balanceOfBZRXAfter >= balanceOfBZRX - stakedBalance[0])
    assert(balanceOfvBZRXAfter == balanceOfvBZRX - stakedBalance[1])
    assert(balanceOfiBZRXAfter == balanceOfiBZRX - stakedBalance[2])
    assert(balanceOfLPTAfter == balanceOfLPT - stakedBalance[3])

    assert True


def testStake_IWantToUnstakeAllMyStakedTokens(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH):

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    LPT.transfer(accounts[1], 1e18, { 'from': accounts[9]})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX, LPT]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX, balanceOfLPT]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

    balances = stakingV1_1.balanceOfByAssets(accounts[1])

    assert(balances[0] == balanceOfBZRX)
    assert(balances[1] == balanceOfiBZRX)
    assert(balances[2] == balanceOfvBZRX)
    assert(balances[3] == balanceOfLPT)

    stakingV1_1.exit({'from': accounts[1]})

    balancesAfter = stakingV1_1.balanceOfByAssets(accounts[1])

    assert(balancesAfter[0] == 0)
    assert(balancesAfter[1] == 0)
    assert(balancesAfter[2] == 0)
    assert(balancesAfter[3] == 0)

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    assert(balanceOfBZRX >= balances[0])
    assert(balanceOfvBZRX == balances[2])
    assert(balanceOfiBZRX == balances[1])
    assert(balanceOfLPT == balances[3])

    assert True


def testStake_IShuldBeAbleToUpdateStakingRewards(requireMainnetFork, fees_extractor, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH):

    # mint some for testing
    BZRX.transfer(accounts[1], 200e18, {'from': BZRX})
    BZRX.approve(iBZRX, 100e18, {'from': accounts[1]})
    iBZRX.mint(accounts[1], 100e18, {'from': accounts[1]})

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})
    LPT.transfer(accounts[1], 1e18, { 'from': accounts[9]})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX, LPT]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX, balanceOfLPT]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})


    # create some fees
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    txSweep = fees_extractor.sweepFees({'from': accounts[9]})


    earnings = stakingV1_1.earned.call(accounts[1])

    assert(earnings[0] > 0)
    assert(earnings[1] > 0)
    assert(earnings[2] > 0)
    assert(earnings[3] > 0)


 