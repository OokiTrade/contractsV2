from brownie import *


exec(open("./scripts/env/set-matic.py").read())

deployer = accounts.at(CHEF.owner(), True)

chefImpl = deployer.deploy(MasterChef_Polygon)
chefProxy = Contract.from_abi("chefProxy", CHEF, Proxy_0_5.abi)

chefProxy.replaceImplementation(chefImpl, {"from": deployer})

SWEEP_FEES.togglePause(False, {"from": deployer})

# account = "ACC"
# account = accounts.at(account, True)
# tokenPrice = iBZRX.tokenPrice()

# CHEF.deposit(2, iBZRX.balanceOf(account), {"from": account})

SWEEP_FEES.sweepFees({"from": accounts[0], "gas_limit": 1000000})