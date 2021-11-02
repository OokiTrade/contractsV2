CHEF =  Contract.from_abi("CHEF", "0xd39Ff512C3e55373a30E94BB1398651420Ae1D43", MasterChef_Polygon.abi)

deployer = accounts.at(CHEF.owner(), True)
SWEEP_FEES = Contract.from_abi("STAKING", "0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", FeeExtractAndDistribute_Polygon.abi)


masterChefProxy = Contract.from_abi("masterChefProxy", address="0xd39Ff512C3e55373a30E94BB1398651420Ae1D43", abi=Proxy.abi)
masterChefImpl = MasterChef_Polygon.deploy({'from': deployer})
masterChefProxy.replaceImplementation(masterChefImpl, {'from': deployer})

sweepImpl = deployer.deploy(FeeExtractAndDistribute_Polygon)
sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
sweepProxy.replaceImplementation(sweepImpl, {"from": deployer})

SWEEP_FEES.togglePause(False, {"from": deployer})

