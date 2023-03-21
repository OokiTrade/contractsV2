deployer = accounts[0]
exec(open("./scripts/env/set-matic.py").read())

sweepImpl = deployer.deploy(FeeExtractAndDistribute_Polygon)
sweepProxy = Contract.from_abi("sweepProxy", SWEEP_FEES, Proxy_0_5.abi)
sweepProxy.replaceImplementation(sweepImpl, {"from": GUARDIAN_MULTISIG})
SWEEP_FEES.setSwapRoute(WMATIC, [WMATIC, USDC], {'from': GUARDIAN_MULTISIG})
SWEEP_FEES.setSwapRoute(LINK, [LINK, WETH, USDC], {'from': GUARDIAN_MULTISIG})
SWEEP_FEES.setSwapRoute(WBTC, [WBTC, WETH, USDC], {'from': GUARDIAN_MULTISIG})