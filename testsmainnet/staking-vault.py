from brownie import *
import pytest

@pytest.fixture(scope="module")
def PriceFeedContract():
    return "0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d"

@pytest.fixture(scope="module")
def ProtocolContract(accounts):
    return accounts[1]

@pytest.fixture(scope="module")
def RewardTokenContract():
    return "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

@pytest.fixture(scope="module")
def ValuationTokenContract():
    return "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

@pytest.fixture(scope="module")
def StakeVault(accounts, Contract, StakingVault, Proxy_0_8, PriceFeedContract, ProtocolContract, RewardTokenContract, ValuationTokenContract):
    #deploy and configure vault
    print("hello")
    s = StakingVault.deploy("", {"from":accounts[0]})
    s_proxy = Proxy_0_8.deploy(s, {"from":accounts[0]})
    s = Contract.from_abi("StakingVault",s_proxy.address, StakingVault.abi)
    s.setPriceFeed(PriceFeedContract, {"from":accounts[0]})
    s.setProtocol(ProtocolContract, {"from":accounts[0]})
    s.setRewardToken(RewardTokenContract, {"from":accounts[0]})
    s.setValuationToken(ValuationTokenContract, {"from":accounts[0]})
    #add backstop tokens
    tokens = ["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]
    update = [True]
    s.updateTokenSupport(tokens, update, tokens, {"from":accounts[0]})
    return s

#deposit into staking vault for a specific token and withdraw.
def test_case1(accounts, Contract, interface, StakeVault, TestToken):
    token_to_deposit = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    token_to_backstop = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    source_of_token = "0x0a59649758aa4d66e25f08dd01271e891fe52199"
    t_deposit = Contract.from_abi("Deposit",token_to_deposit,TestToken.abi)
    t_deposit.transfer(accounts[0], 1e6, {"from":source_of_token})
    starting_balance = interface.IERC20(token_to_deposit).balanceOf(accounts[0])
    t_deposit.approve(StakeVault, 1e6, {"from":accounts[0]})
    StakeVault.deposit(token_to_deposit, token_to_backstop, 1e6, {"from":accounts[0]})
    assert StakeVault.balanceOf(accounts[0], StakeVault.convertToID(token_to_deposit, token_to_backstop)) == 1e18
    print(StakeVault.rewardsPerToken(StakeVault.convertToID(token_to_deposit, token_to_backstop)))
    StakeVault.withdraw(token_to_deposit, token_to_backstop, 1e18, {"from":accounts[0]})
    assert t_deposit.balanceOf(accounts[0]) == starting_balance
#deposit into staking vault, add reward to vault, and withdraw. Check to see if rewards were sent on the withdrawal
def test_case2(accounts, Contract, interface, StakeVault, TestToken):
    token_to_deposit = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    token_to_backstop = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    source_of_token = "0x0a59649758aa4d66e25f08dd01271e891fe52199"
    t_deposit = Contract.from_abi("Deposit",token_to_deposit,TestToken.abi)
    t_deposit.transfer(accounts[0], 1e6, {"from":source_of_token})
    starting_balance = interface.IERC20(token_to_deposit).balanceOf(accounts[0])
    t_deposit.approve(StakeVault, 1e6, {"from":accounts[0]})
    StakeVault.deposit(token_to_deposit, token_to_backstop, 1e6, {"from":accounts[0]})
    t_deposit.approve(StakeVault, 1e6, {"from":source_of_token})
    StakeVault.addRewards(token_to_backstop, 1e6, {"from":source_of_token})
    assert StakeVault.balanceOf(accounts[0], StakeVault.convertToID(token_to_deposit, token_to_backstop)) == 1e18
    print(StakeVault.rewardsPerToken(StakeVault.convertToID(token_to_deposit, token_to_backstop)))
    StakeVault.withdraw(token_to_deposit, token_to_backstop, 1e18, {"from":accounts[0]})
    assert t_deposit.balanceOf(accounts[0]) - starting_balance == 1e6
#deposit into vault, add rewards, manual claim reward, draw on the pool as if being used to backstop a loan, check balance left, and withdraw
def test_case3(accounts, Contract, interface, StakeVault, TestToken, ProtocolContract):
    token_to_deposit = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    token_to_backstop = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    source_of_token = "0x0a59649758aa4d66e25f08dd01271e891fe52199"
    t_deposit = Contract.from_abi("Deposit",token_to_deposit,TestToken.abi)
    t_deposit.transfer(accounts[0], 1e6, {"from":source_of_token})
    starting_balance = interface.IERC20(token_to_deposit).balanceOf(accounts[0])
    t_deposit.approve(StakeVault, 1e6, {"from":accounts[0]})
    StakeVault.deposit(token_to_deposit, token_to_backstop, 1e6, {"from":accounts[0]})
    t_deposit.approve(StakeVault, 1e6, {"from":source_of_token})
    StakeVault.addRewards(token_to_backstop, 1e6, {"from":source_of_token})
    bal = interface.IERC20(token_to_deposit).balanceOf(accounts[0])
    assert StakeVault.balanceOf(accounts[0], StakeVault.convertToID(token_to_deposit, token_to_backstop)) == 1e18
    print(StakeVault.rewardsPerToken(StakeVault.convertToID(token_to_deposit, token_to_backstop)))
    StakeVault.claimRewards([StakeVault.convertToID(token_to_deposit, token_to_backstop)], {"from":accounts[0]})
    assert interface.IERC20(token_to_deposit).balanceOf(accounts[0]) - bal == 1e6
    bal = interface.IERC20(token_to_deposit).balanceOf(ProtocolContract)
    StakeVault.drawOnPool(token_to_backstop, token_to_backstop, 5e5, {"from":ProtocolContract})
    added_amount = interface.IERC20(token_to_deposit).balanceOf(ProtocolContract) - bal
    assert added_amount > 4.95e5
    assert added_amount < 5.05e5
    assert StakeVault.balanceStakedPerID(StakeVault.convertToID(token_to_deposit, token_to_backstop)) < 1e6
    assert StakeVault.getStoredTokenPrice(StakeVault.convertToID(token_to_deposit, token_to_backstop)) < 1e18
    bal = t_deposit.balanceOf(accounts[0])
    print(StakeVault.getStoredTokenPrice(StakeVault.convertToID(token_to_deposit, token_to_backstop)))
    StakeVault.withdraw(token_to_deposit, token_to_backstop, 1e18, {"from":accounts[0]})
    assert t_deposit.balanceOf(accounts[0]) > bal
    assert t_deposit.balanceOf(accounts[0]) - starting_balance == 1e6 - added_amount