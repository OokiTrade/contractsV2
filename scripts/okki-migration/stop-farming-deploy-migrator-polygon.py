exec(open("./scripts/env/set-matic.py").read())

deployer = CHEF.owner();
masterChefProxy = Contract.from_abi("masterChefProxy", address=CHEF, abi=Proxy.abi)
masterChefImpl = MasterChef_Polygon.deploy({'from': deployer})
masterChefProxy.replaceImplementation(masterChefImpl, {'from': deployer})
CHEF.setInitialAltRewardsPerShare({'from': deployer})
CHEF.toggleVestingEnabled(False, {'from': deployer})

CHEF.setLocked(0, False, {'from': deployer})
CHEF.setLocked(2, False, {'from': deployer})
CHEF.setGOVPerBlock(0, {'from': deployer})

swapRate = 19e6
govConverter = FixedSwapTokenConverter.deploy(PGOV, BZRX, swapRate, {'from':  deployer})


FEE_EXTRACTOR = Contract.from_abi("ext", address=BZX.feesController(), abi=FeeExtractAndDistribute_Polygon.abi)
FEE_EXTRACTOR.togglePause(True, {'from': deployer})

