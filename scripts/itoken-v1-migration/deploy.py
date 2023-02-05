exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[0]
iETH_OLD = Contract.from_abi("iETH_OLD", "0x77f973FCaF871459aa58cd81881Ce453759281bC", interface.IToken.abi)

impl = ITokenV1Migrator.deploy({'from': deployer})
proxy = Proxy_0_8.deploy(impl, {'from': deployer})
V1_ITOKEN_MIGRATOR = Contract.from_abi("V1_ITOKEN_MIGRATOR", address=proxy, abi=ITokenV1Migrator.abi)
V1_ITOKEN_MIGRATOR.setTokenPrice(iETH_OLD, iETH_OLD.tokenPrice(), iETH, {'from': deployer})

extractor = TokenExtractor.deploy({'from': deployer})
balance = WETH.balanceOf(iETH_OLD)
print(balance)

calldata = extractor.withdraw.encode_input(WETH, iETH_OLD.owner(), balance)
Contract.from_abi("iETH_OLD", iETH_OLD, AdminSettings.abi).updateSettings(extractor, calldata, {'from': iETH_OLD.owner()})

WETH.approve(iETH, WETH.balanceOf(iETH_OLD.owner()), {'from': iETH_OLD.owner()})
iETH.mint(V1_ITOKEN_MIGRATOR, balance, {'from': iETH_OLD.owner()})
