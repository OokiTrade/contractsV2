exec(open("./scripts/env/set-bsc.py").read())

deployer = CHEF.owner();

# FEE_EXTRACTOR = Contract.from_abi("ext", address=BZX.feesController(), abi=FeeExtractAndDistribute_BSC.abi)
# FEE_EXTRACTOR.togglePause(True, {'from': deployer})

govConverter = FixedSwapTokenConverter.deploy(
    [BGOV],
    [1e18/19], #19 gov == 1 bzrx
    BZRX,
    BGOV,
    {'from':  deployer}
)

