from importlib import import_module
from brownie import *
from enum import Enum

def get_constructor_args(chain):
    module_name = "scripts.env.set_"+chain
    module = import_module(module_name)
    attribute = getattr(module, "Deployment_Immutables")
    return attribute.WETH(),attribute.USDC(), attribute.BZRX(), attribute.VBZRX(), attribute.OOKI()

def deploy_FlashBorrowFees(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return FlashBorrowFeesHelper.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_LoanClosings(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return LoanClosings.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify), LoanClosingsLiquidation.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_LoanMaintenance(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return LoanMaintenance.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify), LoanMaintenance_2.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_LoanOpenings(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return LoanOpenings.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_LoanSettings(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return LoanSettings.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_PauseGuardian(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return ProtocolPausableGuardian.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_ProtocolSettings(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return ProtocolSettings.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_SwapsExternal(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return SwapsExternal.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_VolumeDelta(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return VolumeDelta.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_Receiver(account, values_to_pass, verify=False):
    WETH, USDC, BZRX, VBZRX, OOKI = values_to_pass
    return Receiver.deploy(WETH, USDC, BZRX, VBZRX, OOKI, {"from":account}, publish_source=verify)

def deploy_CurvedInterestRate(account, values_to_pass=None, verify=False):
    return CurvedInterestRate.deploy({"from":account}, publish_source=verify)

def deploy_TickMathV1(account, values_to_pass=None, verify=False):
    return TickMathV1.deploy({"from":account}, publish_source=verify)

def deploy_LiquidationHelper(account, values_to_pass=None, verify=False):
    return LiquidationHelper.deploy({"from":account}, publish_source=verify)

def deploy_VolumeTracker(account, values_to_pass=None, verify=False):
    return VolumeTracker.deploy({"from":account}, publish_source=verify)

class Contracts(Enum):
    def __call__(self, *args, **kwargs):
        return self.value[0](*args, **kwargs)
    FlashBorrowFees = (deploy_FlashBorrowFees,)
    LoanClosings = (deploy_LoanClosings,)
    LoanMaintenance = (deploy_LoanMaintenance,)
    LoanOpenings = (deploy_LoanOpenings,)
    LoanSettings = (deploy_LoanSettings,)
    PauseGuardian = (deploy_PauseGuardian,)
    ProtocolSettings = (deploy_ProtocolSettings,)
    SwapsExternal = (deploy_SwapsExternal,)
    VolumeDelta = (deploy_VolumeDelta,)
    Receiver = (deploy_Receiver,)
    CurvedInterestRate = (deploy_CurvedInterestRate,)
    TickMathV1 = (deploy_TickMathV1,)
    LiquidationHelper = (deploy_LiquidationHelper,)
    VolumeTracker = (deploy_VolumeTracker,)


