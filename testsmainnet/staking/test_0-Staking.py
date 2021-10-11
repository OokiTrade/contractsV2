#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract


# TODO add LPToken
def testStake_UnStake(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts):
    # tx =
    # tx.info()
    balanceOfBZRX = BZRX.balanceOf(accounts[0])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[0]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[0]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[0]})
    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[0]})
    # tx.info()
    # print("tx", tx.events)

    balanceOfBZRXAfter = BZRX.balanceOf(accounts[0])
    balanceOfvBZRXAfter = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRXAfter = iBZRX.balanceOf(accounts[0])

    # due to vesting starated we have small balance vested
    assert(balanceOfBZRXAfter > 0 and balanceOfBZRXAfter/10**18 < 1)
    assert(balanceOfvBZRXAfter == 0)
    assert(balanceOfiBZRXAfter == 0)

    stakedEvents = tx.events['Stake']
    for index, stakedEvent in enumerate(stakedEvents, 0):
        assert(stakedEvent['user'] == accounts[0])
        assert(stakedEvent['token'] == tokens[index])
        assert(stakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    i = 0  # due to extra event transfer does not allighn
    for index, transferEvent in enumerate(transferEvents, 0):
        # most probably a bug in brownie not doing orderdic properly for events
        if (transferEvent['from'] == accounts[i]):
            assert(transferEvent['from'] == accounts[i])
            assert(transferEvent['to'] == stakingV1_1)
            assert(transferEvent['value'] == amounts[i])
            i += 1

    tx = stakingV1_1.unstake(tokens, amounts, {'from':accounts[0]})
    # tx.info()

    unStakedEvents = tx.events['Unstake']
    for index, unStakedEvent in enumerate(unStakedEvents, 0):
        assert(unStakedEvent['user'] == accounts[0])
        assert(unStakedEvent['token'] == tokens[index])
        assert(unStakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    i = 0  # due to extra event transfer does not allighn
    for index, transferEvent in enumerate(transferEvents, 0):
        # most probably a bug in brownie not doing orderdic properly for events
        if (transferEvent['from'] == accounts[i]):
            assert(transferEvent['from'] == stakingV1_1)
            assert(transferEvent['to'] == accounts[0])
            assert(transferEvent['value'] == amounts[index])
            i += 1

    assert True


def testStake_UnStakeOld(requireMainnetFork, stakingV1_1, bzx, LPT_OLD, vBZRX, iBZRX, accounts):
    account = "0x1ee7d451af9fffc192627cebea98d2dae9e4a7c3"
    amounts = [stakingV1_1.balanceOfByAsset(LPT_OLD, account)]
    tokens = [LPT_OLD]
    tx = stakingV1_1.unstake(tokens, amounts, {'from':account})
    assert stakingV1_1.balanceOfByAsset(LPT_OLD, account) == 0
    assert True


def testStake_SweeepFees(requireMainnetFork,fees_extractor, stakingV1_1, bzx,  BZRX, POOL3, iBZRX, accounts, iUSDC, USDC):
    bzrxBalanceBefore = BZRX.balanceOf(stakingV1_1)
    pool3BalanceBefore = POOL3.balanceOf(stakingV1_1)
    tx = fees_extractor.sweepFees({'from': accounts[9]})
    assert bzrxBalanceBefore < BZRX.balanceOf(stakingV1_1)
    assert pool3BalanceBefore < POOL3.balanceOf(stakingV1_1)

    withdrawFeesEvent = tx.events['WithdrawFees']
    assert(withdrawFeesEvent[0]['sender'] == accounts[9])

    convertFeesEvent = tx.events['ConvertFees']
    assert(convertFeesEvent[0]['sender'] == accounts[9])

    distributeFeesEvent = tx.events['DistributeFees']
    assert(distributeFeesEvent[0]['sender'] == accounts[9])

    assert True


def testStake_BZRXProfit(requireMainnetFork, fees_extractor, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH):

    earnedAmounts = stakingV1_1.earned(accounts[0])
    assert(earnedAmounts == (0, 0, 0, 0, 0))
    print("earnedAmounts", earnedAmounts)
    balanceOfBZRX = BZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[0]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [100*10**18, 0, 0]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[0]})

    # iUSDC.borrow(0, 100*10**18, 1*10**18, "0x0000000000000000000000000000000000000000", accounts[0], accounts[0], {'value': Wei("1 ether")})
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    payBorrowingFeeEvent = filterEvents(
        '0xfb6c38ae4fdd498b3a5003f02ca4ca5340dfedb36b1b100c679eb60633b2c0a7', txBorrow.events)
    payBorrowingFeeAmount = int(str(payBorrowingFeeEvent['data']), 0)

    payLendingFeeEvent = filterEvents(
        '0x40a75ae5f7a5336e75f7c7977e12c4b46a9ac0f30de01a2d5b6c1a4f4af63587', txBorrow.events)
    payLendingFeeAmount = int(str(payLendingFeeEvent['data']), 0)

    txSweep = fees_extractor.sweepFees({'from': accounts[9]})

    borrowFee = txSweep.events['WithdrawBorrowingFees'][0]
    assert(borrowFee['sender'] == stakingV1_1)
    assert(borrowFee['token'] == WETH)
    assert(borrowFee['sender'] == stakingV1_1)
    assert(borrowFee['amount'] == payBorrowingFeeAmount)

    lendingFee = txSweep.events['WithdrawLendingFees'][0]
    assert(lendingFee['sender'] == stakingV1_1)
    assert(lendingFee['token'] == USDC)
    assert(lendingFee['sender'] == stakingV1_1)
    assert(lendingFee['amount'] == payLendingFeeAmount)

    assert(txSweep.events['AddRewards'][0]['sender'] == accounts[0])
    bzrxAmount = txSweep.events['AddRewards'][0]['bzrxAmount']
    stableCoinAmount = txSweep.events['AddRewards'][0]['stableCoinAmount']

    assert(txSweep.events['DistributeFees'][0]['sender'] == accounts[0])
    bzrxRewards = txSweep.events['DistributeFees'][0]['bzrxRewards']
    stableCoinRewards = txSweep.events['DistributeFees'][0]['stableCoinRewards']

    assert(bzrxAmount == bzrxRewards)
    assert(stableCoinAmount == stableCoinRewards)
    earned = stakingV1_1.earned(accounts[0])

    # we have roundings for last 1 digit
    print("roundings bzrx", str(bzrxRewards), str(earned[0]))
    assert(bzrxRewards - earned[0] <= 1)
    # we have roundings for last 1 digit
    print("roundings stableCoin", str(stableCoinAmount), str(earned[1]))
    assert(stableCoinAmount - earned[1] <= 1)

    #stakingV1_1.claim(False, {'from': accounts[0]})
    #earned = stakingV1_1.earned(accounts[0])

    # second user staking. he should get zero rewards if he just staked
    earnedAmounts = stakingV1_1.earned(accounts[1])
    assert(earnedAmounts == (0, 0, 0, 0, 0))
    BZRX.transfer(accounts[1], 1000*10**18, {'from': BZRX.address})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts2 = [100*10**18, 0, 0]
    tx = stakingV1_1.stake( tokens, amounts2, {'from': accounts[1]})

    earnedAmounts = stakingV1_1.earned(accounts[1])
    print(str(earnedAmounts))
    assert(earnedAmounts == (0, 0, 0, 0, 0))

    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    txSweepSecondAcc = fees_extractor.sweepFees({'from': accounts[9]})

    print(str(amounts), str(amounts2))
    assert(amounts[0] == amounts2[0])
    assert(stakingV1_1.balanceOfStored(
        accounts[0]) == stakingV1_1.balanceOfStored(accounts[1]))

    '''
    earnedAfter = stakingV1_1.earned(accounts[0])
    earned1After = stakingV1_1.earned(accounts[1])
    print("account[0] before", str(earned[0]))
    print("account[0] after", str(earnedAfter[0] - earned[0]))
    print("account[1] after", str(earned1After[0]))
    print("diff", str(earned1After[0] - earnedAfter[0] + earned[0]))
    '''

    assert True


def filterEvents(topic, events):
    for event in events:
        for key in event.keys():
            if key == 'topic1':
                if event[key] == topic:
                    payBorrowingFeeEvent = event
                    break
    return payBorrowingFeeEvent


def testStake_VestingFees(requireMainnetFork, fees_extractor, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH):
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[0]})
    stakingV1_1.stake([vBZRX], [balanceOfvBZRX], {'from': accounts[0]})

    # borrowing to make fees
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    sweepTx = fees_extractor.sweepFees({'from': accounts[9]})

    earningsDuringVesting = stakingV1_1.earned(accounts[0])
    # vesting already started
    assert(earningsDuringVesting[0] > 0 and earningsDuringVesting[0]/10**18 < 1)
    assert(earningsDuringVesting[1] > 0)
    assert(earningsDuringVesting[2] > 0)
    assert(earningsDuringVesting[3] > 0)
    totalVestingFeesBzrx = earningsDuringVesting[2]
    totalVestingFees3Poll = earningsDuringVesting[3]

    # moving time after vesting end
    chain.sleep(vBZRX.vestingEndTimestamp() - chain.time() + 100)
    chain.mine()
    earnings = stakingV1_1.earned(accounts[0])
    assert(earnings[0] > 0)
    assert(earnings[1] > 0)
    assert(earnings[2] == 0)
    assert(earnings[3] == 0)
    assert(earnings[0] >= totalVestingFeesBzrx)
    assert(earnings[1] >= totalVestingFees3Poll)

    # assert False


def testStake_vestingClaimBZRX(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH):

    vBZRX.transfer(accounts[1], 1000*10**18, {'from': vBZRX.address})
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    stakingV1_1.stake([vBZRX], [balanceOfvBZRX], {'from': accounts[1]})

    # moving time to somewhere 1000 sec after vesting start
    chain.sleep(vBZRX.vestingCliffTimestamp() - chain.time() + 1000)
    chain.mine()

    # BZRX.balanceOf+ vBZRX.balanceOf_bzrx_remaining  should be equal to 1000

    stakingV1_1.exit({'from': accounts[1]})

    assert(BZRX.balanceOf(accounts[1]) > 0)

    assert True


def testStake_vBZRXVotingRigthsShouldDiminishOverTime(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH):

    vBZRX.transfer(accounts[1], 1000e18, {'from': vBZRX})

    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])

    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})

    tokens = [vBZRX]
    amounts = [balanceOfvBZRX]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})
    chain.mine()
    chain.mine()

    # assert False
    # votingPower = stakingV1_1.votingBalanceOfNow(accounts[1])
    # assert(votingPower <= balanceOfvBZRX/2)
    # assert(votingPower > 0)

    # moving time after vesting end
    chain.sleep(vBZRX.vestingEndTimestamp() - chain.time() + 100)
    chain.mine()

    stakingV1_1.claimBzrx({'from': accounts[1]})
    
    votingPower = stakingV1_1.votingBalanceOfNow(accounts[1])
    assert(votingPower == 0)
    assert True


def testStake_vBZRXVotingRigthsShouldDiminishOverTime2(requireMainnetFork, stakingV1_1, bzx,  BZRX, vBZRX, iBZRX, LPT, accounts, iUSDC, USDC, WETH):

    vBZRX.transfer(accounts[1], 100e18, {'from': vBZRX})

    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])

    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})

    tokens = [vBZRX]
    amounts = [balanceOfvBZRX]
    tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})
    votingPower = stakingV1_1.votingBalanceOfNow(accounts[1])
    assert(votingPower < balanceOfvBZRX/2)

    # moving time to somewhere 1000 sec after vesting start
    chain.sleep(vBZRX.vestingCliffTimestamp() - chain.time() + 1000)
    chain.mine()

    votingPower = stakingV1_1.votingBalanceOfNow(accounts[1])
    assert(votingPower < balanceOfvBZRX/2)

    # moving time after vesting end
    chain.sleep(vBZRX.vestingEndTimestamp() - chain.time() + 100)
    chain.mine()

    votingPower = stakingV1_1.votingBalanceOfNow(accounts[1])
    assert(votingPower < balanceOfvBZRX)
    assert True
