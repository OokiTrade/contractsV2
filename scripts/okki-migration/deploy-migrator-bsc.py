exec(open("./scripts/env/set-bsc.py").read())

deployer = CHEF.owner();

FEE_EXTRACTOR = Contract.from_abi("ext", address=BZX.feesController(), abi=FeeExtractAndDistribute_BSC.abi)
FEE_EXTRACTOR.togglePause(True, {'from': deployer})

govOokiConverter = FixedSwapTokenConverter.deploy(
    [BGOV, BZRX],
    [1e6/1.9, 10e6], #19 gov == 1 bzrx == 10 ooki, 1.9 gov == 1 ooki
    OOKI,
    BZRX,
    {'from':  deployer}
)

