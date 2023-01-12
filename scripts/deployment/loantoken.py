from importlib import import_module
from brownie import *
from enum import Enum

def get_constructor_args(chain):
    module_name = "scripts.env.set_"+chain
    module = import_module(module_name)
    attribute = getattr(module, "Deployment_Immutables")
    return attribute.ARB_CALLER(), module.BZX.address, attribute.WETH()

def deploy_LoanToken(account, values_to_pass, verify=False):
    arb, bzx, weth = values_to_pass
    return LoanTokenLogicStandard.deploy(arb, bzx, weth, {"from":account}, publish_source=verify)
def deploy_LoanTokenWeth(account, values_to_pass, verify=False):
    arb, bzx, weth = values_to_pass
    return LoanTokenLogicWeth.deploy(arb, bzx, weth, {"from":account}, publish_source=verify)

class Contracts(Enum):
    def __call__(self, *args, **kwargs):
        return self.value[0](*args, **kwargs)
    
    LoanToken = (deploy_LoanToken,)
    LoanTokenWeth = (deploy_LoanTokenWeth,)
