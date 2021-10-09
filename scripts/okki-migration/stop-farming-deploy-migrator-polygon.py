exec(open("./scripts/env/set-matic.py").read())

deployer = CHEF.owner();
masterChefProxy = Contract.from_abi("masterChefProxy", address=CHEF, abi=Proxy.abi)
masterChefImpl = MasterChef_Polygon.deploy({'from': deployer})
masterChefProxy.replaceImplementation(masterChefImpl, {'from': deployer})
CHEF.setInitialAltRewardsPerShare({'from': deployer})
CHEF.toggleVesting(False, {'from': deployer})

CHEF.setLocked(0, False, {'from': deployer})
CHEF.setLocked(2, False, {'from': deployer})
CHEF.setGOVPerBlock(0, {'from': deployer})

FEE_EXTRACTOR = Contract.from_abi("ext", address=BZX.feesController(), abi=FeeExtractAndDistribute_Polygon.abi)
FEE_EXTRACTOR.togglePause(True, {'from': deployer})

govOokiConverter = FixedSwapTokenConverter.deploy(
    [PGOV, BZRX],
    [1e6/1.9, 10e6], #19 gov == 1 bzrx == 10 ooki, 1.9 gov == 1 ooki
    OOKI,
    BZRX,
    {'from':  deployer}
)

