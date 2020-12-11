#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork"
            or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def setFeesController(bzx, stakingV1, accounts):
    bzx.setFeesController(stakingV1, {"from": bzx.owner()})
    assets = [
        "0x56d811088235F11C8920698a204A5010a788f4b3",  # BZRX
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # WETH
        "0x6B175474E89094C44Da98b954EedeAC495271d0F",  # DAI
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  # USDC
        "0xdAC17F958D2ee523a2206206994597C13D831ec7",  # USDT
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",  # WBTC
        "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",  # AAVE
        "0xdd974D5C2e2928deA5F71b9825b8b646686BD200",  # KNC
        "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",  # MKR
        "0x514910771AF9Ca656af840dff83E8264EcF986CA",  # LINK
        "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",  # YFI
    ]
    bzx.withdrawFees(assets, accounts[8], 0, {'from': stakingV1})


@pytest.fixture(scope="module")
def vBZRX(accounts):
    vBZRX = loadContractFromEtherscan(
        "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX")
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def iUSDC(accounts):
    iUSDC = loadContractFromEtherscan(
        "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC")
    return iUSDC


@pytest.fixture(scope="module")
def WETH(accounts):
    WETH = loadContractFromEtherscan(
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH")
    return WETH


@pytest.fixture(scope="module")
def USDC(accounts):
    USDC = loadContractFromEtherscan(
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "USDC")
    return USDC


@pytest.fixture(scope="module")
def BZRX(accounts):
    BZRX = loadContractFromEtherscan(
        "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX")
    BZRX.transfer(accounts[0], 1000*10**18, {'from': BZRX.address})
    return BZRX


@pytest.fixture(scope="module")
def iBZRX(accounts, BZRX):
    iBZRX = loadContractFromEtherscan(
        "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", "iBZRX")

    BZRX.approve(iBZRX, 10*10**50, {'from': accounts[0]})
    iBZRX.mint(accounts[0], 100*10**18, {'from': accounts[0]})
    return iBZRX


def loadContractFromEtherscan(address, alias):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_explorer(address)
        contract.set_alias(alias)
        return contract


# TODO add LPToken
def testStake_UnStake(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts):
    # tx =
    # tx.info()
    balanceOfBZRX = BZRX.balanceOf(accounts[0])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1, balanceOfBZRX, {'from': accounts[0]})
    vBZRX.approve(stakingV1, balanceOfvBZRX, {'from': accounts[0]})
    iBZRX.approve(stakingV1, balanceOfiBZRX, {'from': accounts[0]})
    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]
    tx = stakingV1.stake(
        tokens, amounts, accounts[0])
    # tx.info()
    # print("tx", tx.events)

    balanceOfBZRXAfter = BZRX.balanceOf(accounts[0])
    balanceOfvBZRXAfter = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRXAfter = iBZRX.balanceOf(accounts[0])

    assert(balanceOfBZRXAfter == 0)
    assert(balanceOfvBZRXAfter == 0)
    assert(balanceOfiBZRXAfter == 0)

    delegateChanged = stakedEvents = tx.events['DelegateChanged']
    assert(delegateChanged['user'] == accounts[0])
    assert(delegateChanged['oldDelegate'] ==
           '0x0000000000000000000000000000000000000000')
    assert(delegateChanged['newDelegate'] == accounts[0])

    stakedEvents = tx.events['Staked']
    for index, stakedEvent in enumerate(stakedEvents, 0):
        assert(stakedEvent['user'] == accounts[0])
        assert(stakedEvent['token'] == tokens[index])
        assert(stakedEvent['delegate'] == accounts[0])
        assert(stakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    for index, transferEvent in enumerate(transferEvents, 0):
        assert(transferEvent['from'] == accounts[0])
        assert(transferEvent['to'] == stakingV1)
        assert(transferEvent['value'] == amounts[index])

    tx = stakingV1.unStake(tokens, amounts)
    # tx.info()

    unStakedEvents = tx.events['Unstaked']
    for index, unStakedEvent in enumerate(unStakedEvents, 0):
        assert(unStakedEvent['user'] == accounts[0])
        assert(unStakedEvent['token'] == tokens[index])
        assert(unStakedEvent['delegate'] == accounts[0])
        assert(unStakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    for index, transferEvent in enumerate(transferEvents, 0):
        assert(transferEvent['from'] == stakingV1)
        assert(transferEvent['to'] == accounts[0])
        assert(transferEvent['value'] == amounts[index])

    assert True


def testStake_UnStake_WithDelegate(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts):
    # tx =
    # tx.info()
    balanceOfBZRX = BZRX.balanceOf(accounts[0])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1, balanceOfBZRX, {'from': accounts[0]})
    vBZRX.approve(stakingV1, balanceOfvBZRX, {'from': accounts[0]})
    iBZRX.approve(stakingV1, balanceOfiBZRX, {'from': accounts[0]})
    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]
    tx = stakingV1.stake(tokens, amounts, accounts[1])
    # tx.info()
    # print("tx", tx.events)

    balanceOfBZRXAfter = BZRX.balanceOf(accounts[0])
    balanceOfvBZRXAfter = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRXAfter = iBZRX.balanceOf(accounts[0])

    assert(balanceOfBZRXAfter == 0)
    assert(balanceOfvBZRXAfter == 0)
    assert(balanceOfiBZRXAfter == 0)

    delegateChanged = tx.events['DelegateChanged']
    assert(delegateChanged['user'] == accounts[0])
    assert(delegateChanged['oldDelegate'] ==
           '0x0000000000000000000000000000000000000000')
    assert(delegateChanged['newDelegate'] == accounts[1])

    stakedEvents = tx.events['Staked']
    for index, stakedEvent in enumerate(stakedEvents, 0):
        assert(stakedEvent['user'] == accounts[0])
        assert(stakedEvent['token'] == tokens[index])
        assert(stakedEvent['delegate'] == accounts[1])
        assert(stakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    for index, transferEvent in enumerate(transferEvents, 0):
        assert(transferEvent['from'] == accounts[0])
        assert(transferEvent['to'] == stakingV1)
        assert(transferEvent['value'] == amounts[index])

    tx = stakingV1.unStake(tokens, amounts)
    # tx.info()

    unStakedEvents = tx.events['Unstaked']
    for index, unStakedEvent in enumerate(unStakedEvents, 0):
        assert(unStakedEvent['user'] == accounts[0])
        assert(unStakedEvent['token'] == tokens[index])
        assert(unStakedEvent['delegate'] == accounts[1])
        assert(unStakedEvent['amount'] == amounts[index])

    transferEvents = tx.events['Transfer']
    for index, transferEvent in enumerate(transferEvents, 0):
        assert(transferEvent['from'] == stakingV1)
        assert(transferEvent['to'] == accounts[0])
        assert(transferEvent['value'] == amounts[index])

    assert True


def testStake_SweeepFees(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC):
    tx = stakingV1.sweepFees()
    # events = tx.events[]


def testStake_BZRXProfit(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH):

    earnedAmounts = stakingV1.earned(accounts[0])
    assert(earnedAmounts == (0, 0, 0, 0))
    print("earnedAmounts", earnedAmounts)
    balanceOfBZRX = BZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1, balanceOfBZRX, {'from': accounts[0]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, 0, 0]
    tx = stakingV1.stake(tokens, amounts, accounts[1])

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

    txSweep = stakingV1.sweepFees()

    borrowFee = txSweep.events['WithdrawBorrowingFees'][0]
    assert(borrowFee['sender'] == stakingV1)
    assert(borrowFee['token'] == WETH)
    assert(borrowFee['sender'] == stakingV1)
    assert(borrowFee['amount'] == payBorrowingFeeAmount)

    lendingFee = txSweep.events['WithdrawLendingFees'][0]
    assert(lendingFee['sender'] == stakingV1)
    assert(lendingFee['token'] == USDC)
    assert(lendingFee['sender'] == stakingV1)
    assert(lendingFee['amount'] == payLendingFeeAmount)

    assert(txSweep.events['RewardAdded'][0]['sender'] == accounts[0])
    bzrxAmount = txSweep.events['RewardAdded'][0]['bzrxAmount']
    stableCoinAmount = txSweep.events['RewardAdded'][0]['stableCoinAmount']

    assert(txSweep.events['DistributeFees'][0]['sender'] == accounts[0])
    bzrxRewards = txSweep.events['DistributeFees'][0]['bzrxRewards']
    stableCoinRewards = txSweep.events['DistributeFees'][0]['stableCoinRewards']

    assert(bzrxAmount == bzrxRewards)
    assert(stableCoinAmount == stableCoinRewards)
    earned = stakingV1.earned(accounts[0])

    # we have roundings for last 3 digits
    assert(bzrxRewards - earned[0] < 1000)
    # we have roundings for last 3 digits
    assert(stableCoinAmount - earned[1] < 1000)

    # second user staking. he should get zero rewards if he just staked
    earnedAmounts = stakingV1.earned(accounts[1])
    assert(earnedAmounts == (0, 0, 0, 0))
    BZRX.transfer(accounts[1], 1000*10**18, {'from': BZRX.address})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])

    BZRX.approve(stakingV1, balanceOfBZRX, {'from': accounts[1]})

    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, 0, 0]
    tx = stakingV1.stake(
        tokens, amounts, accounts[1], {'from': accounts[1]})

    earnedAmounts = stakingV1.earned(accounts[1])
    assert(earnedAmounts == (0, 0, 0, 0))

    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    txSweepSecondAcc = stakingV1.sweepFees()

    # TODO fees to not match here @Tom
    assert False


def filterEvents(topic, events):
    for event in events:
        for key in event.keys():
            if key == 'topic1':
                if event[key] == topic:
                    payBorrowingFeeEvent = event
                    break
    return payBorrowingFeeEvent


def testStake_Vesting(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC, USDC, WETH):

    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    vBZRX.approve(stakingV1, balanceOfvBZRX, {'from': accounts[0]})
    stakingV1.stake([vBZRX], [balanceOfvBZRX], accounts[0])

    # borrowing to make fees
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 1*10**18
    collateralAddress = "0x0000000000000000000000000000000000000000"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'value': Wei(collateralAmount)})

    # stakingV1

    # moving time
    # chain.sleep(vBZRX.vestingCliffTimestamp() - chain.time())

    assert False
