exec(open("./scripts/env/set-bsc.py").read())

deployer = CHEF.owner();
swapRate = 19e6
govConverter = FixedSwapTokenConverter.deploy(BGOV, BZRX, swapRate, {'from':  deployer})

