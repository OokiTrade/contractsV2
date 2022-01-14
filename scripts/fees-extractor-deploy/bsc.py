CHEF = Contract.from_abi("CHEF", "0x1FDCA2422668B961E162A8849dc0C2feaDb58915", MasterChef_BSC.abi)
SWEEP_FEES = Contract.from_abi("STAKING", "0x5c9b515f05a0E2a9B14C171E2675dDc1655D9A1c", FeeExtractAndDistribute_BSC.abi)

deployer = accounts.at(CHEF.owner(), True)
masterChefProxy = Contract.from_abi("masterChefProxy", address=CHEF.address, abi=Proxy.abi)
masterChefImpl = MasterChef_BSC.deploy({'from': masterChefProxy.owner()})
masterChefProxy.replaceImplementation(masterChefImpl, {'from': masterChefProxy.owner()})

sweepImpl = deployer.deploy(FeeExtractAndDistribute_BSC)
sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
sweepProxy.replaceImplementation(sweepImpl, {"from": deployer})

CHEF.setInitialAltRewardsPerShare({'from': deployer})
SWEEP_FEES.togglePause(False, {"from": deployer})

