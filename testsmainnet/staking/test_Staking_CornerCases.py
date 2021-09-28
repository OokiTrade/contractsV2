#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")



def testStake_Multiple_People(requireMainnetFork, stakingV1_1, fees_extractor, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[2], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[3], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[4], 50e18, {
                   'from': vBZRX})

    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[4]})

    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[1]})
    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[2]})
    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[3]})
    stakingV1_1.stake([vBZRX], [50e18], {'from': accounts[4]})

    earned1 = stakingV1_1.earned.call(accounts[1])
    earned2 = stakingV1_1.earned.call(accounts[2])
    earned3 = stakingV1_1.earned.call(accounts[3])
    earned4 = stakingV1_1.earned.call(accounts[4])

    # due to staking and stake block difference, people who stake first have more vesties inside
    assert earned1[0] >= earned2[0] >= earned3[0] >= earned4[0]

    makeSomeFees(BZRX, accounts, fees_extractor, iUSDC)

    earned1After = stakingV1_1.earned.call(accounts[1])
    earned2After = stakingV1_1.earned.call(accounts[2])
    earned3After = stakingV1_1.earned.call(accounts[3])
    earned4After = stakingV1_1.earned.call(accounts[4])

    print(earned1After)
    print(earned2After)
    print(earned3After)
    print(earned4After)

    ## people who stake the same amounts first have slightly more earned and slightly less vested
    assert earned1After[0] >= earned2After[0] >= earned3After[0] >= earned4After[0]
    assert(checkSmallDiff(earned1After[0], earned2After[0]))
    assert(checkSmallDiff(earned1After[0], earned3After[0]))

    assert(checkSmallDiff(earned1After[1], earned2After[1]))
    assert(checkSmallDiff(earned1After[1], earned3After[1]))
    assert earned1After[1] >= earned4After[1]

    assert(checkSmallDiff(earned1After[2], earned2After[2]))
    assert(checkSmallDiff(earned1After[2], earned3After[2]))
    assert earned1After[2] >= earned4After[2]

    assert(checkSmallDiff(earned1After[3], earned2After[3]))
    assert(checkSmallDiff(earned1After[3], earned3After[3]))
    assert earned1After[3] >= earned4After[3]

    # approximately account4 has to have half revenue of accounts 1 2 3
    assert abs(earned3After[0]/10**18 - earned4After[0] * 2/10**18) < 1

    #assert False

def checkSmallDiff(a, b, precision=18):
    return abs(a - b) < 10**precision

def testStake_Multiple_VestiesMoveTime(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[2], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[3], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[4], 50e18, {
                   'from': vBZRX})

    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[4]})

    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[1]})
    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[2]})
    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[3]})
    stakingV1_1.stake([vBZRX], [50e18], {'from': accounts[4]})

    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[1]})
    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[2]})
    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[3]})
    stakingV1_1.unstake([vBZRX], [50e18], {'from': accounts[4]})

    bzrxBalanceOf = BZRX.balanceOf(stakingV1_1)

    print(stakingV1_1.earned.call(accounts[1]))
    print(stakingV1_1.earned.call(accounts[2]))
    print(stakingV1_1.earned.call(accounts[3]))
    print(stakingV1_1.earned.call(accounts[4]))

    stakingV1_1.claim(False, {'from': accounts[1]})
    stakingV1_1.claim(False, {'from': accounts[2]})
    stakingV1_1.claim(False, {'from': accounts[3]})
    stakingV1_1.claim(False, {'from': accounts[4]})

    #stakingV1_1.exit({'from': accounts[1]})
    #stakingV1_1.exit({'from': accounts[2]})
    #stakingV1_1.exit({'from': accounts[3]})
    #stakingV1_1.exit({'from': accounts[4]})

    # math rounding lefties
    assert BZRX.balanceOf(stakingV1_1) < bzrxBalanceOf


    #half way thru vesting
    # chain.sleep(1665604800 - chain.time())
    # chain.mine()

    #assert False



def testStake_Multiple_VestiesMoveMultipleTime(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[2], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[3], 100e18, {
                   'from': vBZRX})

    vBZRX.transfer(accounts[4], 50e18, {
                   'from': vBZRX})

    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1_1, 2**256-1, {'from': accounts[4]})

    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[1]})


    # 1/4 to vesting end
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()

    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[2]})
    
    # another 1/4
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()
    
    stakingV1_1.stake([vBZRX], [100e18], {'from': accounts[3]})

    # another 1/4
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()

    stakingV1_1.stake([vBZRX], [50e18], {'from': accounts[4]})

    # 1000 sec after vesting ended
    chain.sleep(vBZRX.vestingEndTimestamp() - chain.time() + 1000)
    chain.mine()

    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[1]})
    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[2]})
    stakingV1_1.unstake([vBZRX], [100e18], {'from': accounts[3]})
    stakingV1_1.unstake([vBZRX], [50e18], {'from': accounts[4]})

    bzrxBalanceOf = BZRX.balanceOf(stakingV1_1)
    stakingV1_1.claim(False, {'from': accounts[1]})
    stakingV1_1.claim(False, {'from': accounts[2]})
    stakingV1_1.claim(False, {'from': accounts[3]})
    stakingV1_1.claim(False, {'from': accounts[4]})

    # math rounding lefties
    assert BZRX.balanceOf(stakingV1_1) < bzrxBalanceOf

    print(BZRX.balanceOf(stakingV1_1))
    print(stakingV1_1.earned.call(accounts[1]))
    print(stakingV1_1.earned.call(accounts[2]))
    print(stakingV1_1.earned.call(accounts[3]))
    print(stakingV1_1.earned.call(accounts[4]))

    #half way thru vesting
    # chain.sleep(1665604800 - chain.time())
    # chain.mine()

    #ssert False

def makeSomeFees(BZRX, accounts, fees_extractor, iUSDC):
    BZRX.transfer(accounts[0], 10000e18, {
                  'from': BZRX})
    BZRX.approve(iUSDC, 2**256-1, {'from': accounts[0]})
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 2000*10**18
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, BZRX,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'allow_revert': 1})

    fees_extractor.sweepFees({'from': accounts[9]})
