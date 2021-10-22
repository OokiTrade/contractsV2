from brownie import *


exec(open("./scripts/env/set-matic.py").read())

deployer = accounts.at(CHEF.owner(), True)

chefImpl = deployer.deploy(MasterChef_Polygon)
chefProxy = Contract.from_abi("chefProxy", CHEF, Proxy_0_5.abi)

chefProxy.replaceImplementation(chefImpl, {"from": deployer})

sweepImpl = deployer.deploy(FeeExtractAndDistribute_Polygon)
sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
sweepProxy.replaceImplementation(sweepImpl, {"from": deployer})


SWEEP_FEES.togglePause(False, {"from": deployer})

# account = "0xcF7C03cf8bAbeB0a81992B49E326788906F026E0"
# account = accounts.at(account, True)
# tokenPrice = iBZRX.tokenPrice()

# CHEF.deposit(2, iBZRX.balanceOf(account), {"from": account})

SWEEP_FEES.sweepFees({"from": accounts[0], "gas_limit": 10000000})