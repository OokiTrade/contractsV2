exec(open("./scripts/env/set-bsc.py").read())

deployer = CHEF.owner();

swapRate = 19e6 #19 gov per bzrx
govConverter = FixedSwapTokenConverter.deploy(BGOV, BZRX, swapRate, {'from':  deployer})
FEE_EXTRACTOR = Contract.from_abi("ext", address=BZX.feesController(), abi=FeeExtractAndDistribute_BSC.abi)
FEE_EXTRACTOR.togglePause(True, {'from': deployer})

