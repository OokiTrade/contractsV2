from brownie import *
from enum import Enum

def deploy_Delegation(account, values_to_pass=None, verify=False):
    return VoteDelegator.deploy({"from":account}, publish_source=verify)

def deploy_AdminSettings(account, values_to_pass=None, verify=False):
    return AdminSettings.deploy({"from":account}, publish_source=verify)

def deploy_Rewards(account, values_to_pass=None, verify=False):
    return Rewards.deploy({"from":account}, publish_source=verify)

def deploy_StakeUnstake(account, values_to_pass=None, verify=False):
    return StakeUnStake.deploy({"from":account}, publish_source=verify)

def deploy_StakingPausableGuardian(account, values_to_pass=None, verify=False):
    return StakingPausableGuardian.deploy({"from":account}, publish_source=verify)

def deploy_Voting(account, values_to_pass=None, verify=False):
    return Voting.deploy({"from":account}, publish_source=verify)

class Contracts(Enum):
    def __call__(self, *args, **kwargs):
        return self.value[0](*args, **kwargs)
    
    Delegation = (deploy_Delegation,)
    AdminSettings = (deploy_AdminSettings,)
    Rewards = (deploy_Rewards,)
    StakeUnstake = (deploy_StakeUnstake,)
    StakingPausableGuardian = (deploy_StakingPausableGuardian,)
    Voting = (deploy_Voting,)