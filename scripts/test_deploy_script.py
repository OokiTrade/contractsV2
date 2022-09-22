from brownie import *
from scripts.deployment.protocol import Contracts as ProtocolContracts
from scripts.deployment.loantoken import Contracts as LoanTokenContracts
from scripts.deployment.staking import Contracts as StakingContracts
from scripts.deployment.protocol import get_constructor_args as protocol_args
from scripts.deployment.loantoken import get_constructor_args as loantoken_args
chain = "eth"
account_to_use = accounts[0]
receiver_contract = ProtocolContracts.Receiver(account_to_use, protocol_args(chain))
loantokenlogic = LoanTokenContracts.LoanToken(account_to_use, loantoken_args(chain))
delegation_logic = StakingContracts.Delegation(account_to_use)
print(receiver_contract)
print(loantokenlogic)
print(delegation_logic)