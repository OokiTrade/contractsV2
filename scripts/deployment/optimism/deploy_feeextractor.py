from eth_abi.packed import encode_abi_packed
exec(open("./scripts/env/set-optimism.py").read())

deployer = accounts.load('deployer')
#sweepImpl = deployer.deploy(FeeExtractAndDistribute_Optimism) #0x86290f885b56d6e180Ac18b4792766c92A78d08c
sweepImpl = Contract.from_abi("SWEEP_FEES", "0x86290f885b56d6e180Ac18b4792766c92A78d08c", FeeExtractAndDistribute_Optimism.abi)
#proxy = deployer.deploy(Proxy_0_8, sweepImpl) #0xEfC00F2b226130461f6C9E9C5A5e465BF23FFD77
proxy = Contract.from_abi("SWEEP_FEES", "0xEfC00F2b226130461f6C9E9C5A5e465BF23FFD77", Proxy_0_8.abi)
SWEEP_FEES = Contract.from_abi("SWEEP_FEES", "0xEfC00F2b226130461f6C9E9C5A5e465BF23FFD77", FeeExtractAndDistribute_Optimism.abi)
SWEEP_FEES.setBridge('0x9D39Fc627A6d9d9F8C831c16995b209548cc3401', {'from': deployer})
SWEEP_FEES.setSlippage(10000, {'from': deployer})
SWEEP_FEES.setTreasuryWallet('0x8c02edee0c759df83e31861d11e6918dd93427d2', {'from': deployer})

tokensSupported = [DAI.address, USDT.address, USDC.address, WETH.address, WBTC.address, FRAX.address, OP.address]
DAI_PATH = encode_abi_packed(["address","uint24","address"],[DAI.address,500,USDC.address])
USDT_PATH = encode_abi_packed(["address","uint24","address"],[USDT.address,500,USDC.address])
USDC_PATH = b''
WETH_PATH = encode_abi_packed(["address","uint24","address"],[WETH.address,500,USDC.address])
WBTC_PATH = encode_abi_packed(["address","uint24","address"],[WBTC.address,500,USDC.address])
FRAX_PATH = encode_abi_packed(["address","uint24","address"],[FRAX.address,500,USDC.address])
OP_PATH = encode_abi_packed(["address","uint24","address"],[OP.address,500,USDC.address])

SWEEP_FEES.setFeeTokens(tokensSupported, [DAI_PATH, USDT_PATH, USDC_PATH, WETH_PATH, WBTC_PATH, FRAX_PATH, OP_PATH], {"from": deployer})
SWEEP_FEES.setBridgeApproval(USDC, {'from': deployer})
SWEEP_FEES.changeGuardian(GUARDIAN_MULTISIG, {'from': deployer})

#BZX.setFeesController(SWEEP_FEES, {'from': BZX.owner()})