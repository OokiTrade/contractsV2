#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


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
def LPT(accounts, TestToken):
    LPT = loadContractFromAbi(
        "0xe26A220a341EAca116bDa64cF9D5638A935ae629", "LPT", TestToken.abi)
    return LPT


@pytest.fixture(scope="module")
def vBZRX(accounts, BZRXVestingToken):
    vBZRX = loadContractFromAbi(
        "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX", BZRXVestingToken.abi)
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    iUSDC = loadContractFromAbi(
        "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", LoanTokenLogicStandard.abi)
    return iUSDC


@pytest.fixture(scope="module")
def WETH(accounts, TestWeth):
    WETH = loadContractFromAbi(
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH", TestWeth.abi)
    return WETH


@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    USDC = loadContractFromAbi(
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "USDC", TestToken.abi)
    return USDC


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    BZRX = loadContractFromAbi(
        "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX", TestToken.abi)
    BZRX.transfer(accounts[0], 1000*10**18, {'from': BZRX.address})
    return BZRX


@pytest.fixture(scope="module")
def iBZRX(accounts, BZRX, LoanTokenLogicStandard):
    iBZRX = loadContractFromAbi(
        "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", "iBZRX", LoanTokenLogicStandard.abi)
    BZRX.approve(iBZRX, 10*10**50, {'from': accounts[0]})
    iBZRX.mint(accounts[0], 100*10**18, {'from': accounts[0]})
    return iBZRX


# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

 
def testStake_Multiple_People(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[2], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[3], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[4], 500e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[4]})

    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[1]})
    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[2]})
    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[3]})
    stakingV1.stake([vBZRX], [500e18], {'from': accounts[4]})

    earned1 = stakingV1.earned(accounts[1])
    earned2 = stakingV1.earned(accounts[2])
    earned3 = stakingV1.earned(accounts[3])
    earned4 = stakingV1.earned(accounts[4])

    # due to staking and stake block difference, people who stake first have more vesties inside
    assert earned1[0] > earned2[0] > earned3[0] > earned4[0]

    makeSomeFees(BZRX, accounts, iUSDC, stakingV1)

    earned1After = stakingV1.earned(accounts[1])
    earned2After = stakingV1.earned(accounts[2])
    earned3After = stakingV1.earned(accounts[3])
    earned4After = stakingV1.earned(accounts[4])

    print(earned1After)
    print(earned2After)
    print(earned3After)
    print(earned4After)

    ## people who stake the same amounts first have slightly more earned and slightly less vested
    assert earned1After[0] > earned2After[0] > earned3After[0] > earned4After[0]
    assert earned1After[1] > earned2After[1] > earned3After[1] > earned4After[1]
    assert earned3After[2] > earned2After[2] > earned1After[2] > earned4After[2]
    assert earned3After[3] > earned2After[3] > earned1After[3] > earned4After[3]

    # approximately account4 has to have half revenue of accounts 1 2 3
    assert abs(earned3After[0]/10**18 - earned4After[0] * 2/10**18) < 1

    #assert False



def testStake_Multiple_VestiesMoveTime(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[2], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[3], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[4], 500e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[4]})

    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[1]})
    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[2]})
    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[3]})
    stakingV1.stake([vBZRX], [500e18], {'from': accounts[4]})

    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[1]})
    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[2]})
    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[3]})
    stakingV1.unstake([vBZRX], [500e18], {'from': accounts[4]})

    print(BZRX.balanceOf(stakingV1))
    print(stakingV1.earned(accounts[1]))
    print(stakingV1.earned(accounts[2]))
    print(stakingV1.earned(accounts[3]))
    print(stakingV1.earned(accounts[4]))

    stakingV1.claim({'from': accounts[1]})
    stakingV1.claim({'from': accounts[2]})
    stakingV1.claim({'from': accounts[3]})
    stakingV1.claim({'from': accounts[4]})

    #stakingV1.exit({'from': accounts[1]})
    #stakingV1.exit({'from': accounts[2]})
    #stakingV1.exit({'from': accounts[3]})
    #stakingV1.exit({'from': accounts[4]})

    # math rounding lefties
    assert BZRX.balanceOf(stakingV1)/10**18 < 1 


    #half way thru vesting
    # chain.sleep(1665604800 - chain.time())
    # chain.mine()

    #assert False



def testStake_Multiple_VestiesMoveMultipleTime(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts, iUSDC):
    vBZRX.transfer(accounts[1], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[2], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[3], 1000e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.transfer(accounts[4], 500e18, {
                   'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[1]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[2]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[3]})
    vBZRX.approve(stakingV1, 2**256-1, {'from': accounts[4]})

    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[1]})


    # 1/4 to vesting end
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()

    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[2]})
    
    # another 1/4
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()
    
    stakingV1.stake([vBZRX], [1000e18], {'from': accounts[3]})

    # another 1/4
    chain.sleep(int((vBZRX.vestingEndTimestamp() - chain.time())/4))
    chain.mine()

    stakingV1.stake([vBZRX], [500e18], {'from': accounts[4]})

    # 1000 sec after vesting ended
    chain.sleep(vBZRX.vestingEndTimestamp() - chain.time() + 1000)
    chain.mine()

    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[1]})
    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[2]})
    stakingV1.unstake([vBZRX], [1000e18], {'from': accounts[3]})
    stakingV1.unstake([vBZRX], [500e18], {'from': accounts[4]})

    stakingV1.claim({'from': accounts[1]})
    stakingV1.claim({'from': accounts[2]})
    stakingV1.claim({'from': accounts[3]})
    stakingV1.claim({'from': accounts[4]})

    # math rounding lefties
    assert BZRX.balanceOf(stakingV1)/10**18 < 1 

    print(BZRX.balanceOf(stakingV1))
    print(stakingV1.earned(accounts[1]))
    print(stakingV1.earned(accounts[2]))
    print(stakingV1.earned(accounts[3]))
    print(stakingV1.earned(accounts[4]))

    #half way thru vesting
    # chain.sleep(1665604800 - chain.time())
    # chain.mine()

    #ssert False

def makeSomeFees(BZRX, accounts, iUSDC, stakingV1):
    BZRX.transfer(accounts[0], 1000000e18, {
                  'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
    BZRX.approve(iUSDC, 2**256-1, {'from': accounts[0]})
    borrowAmount = 100*10**6
    borrowTime = 7884000
    collateralAmount = 2000*10**18
    collateralAddress = "0x56d811088235F11C8920698a204A5010a788f4b3"
    txBorrow = iUSDC.borrow("", borrowAmount, borrowTime, collateralAmount, collateralAddress,
                            accounts[0], accounts[0], b"", {'from': accounts[0], 'allow_revert': 1})

    stakingV1.sweepFees()
