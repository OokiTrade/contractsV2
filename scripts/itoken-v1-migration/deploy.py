# exec(open("./scripts/env/set-eth.py").read())
# deployer = accounts[0]
# DAOGuardiansMultisig = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"
# iETH_OLD = Contract.from_abi("iETH_OLD", "0x77f973FCaF871459aa58cd81881Ce453759281bC", LoanTokenLogicV4.abi)
#
# impl = ITokenV1Migrator.deploy({'from': deployer})
# proxy = Proxy_0_8.deploy(impl, {'from': deployer})
# V1_ITOKEN_MIGRATOR = Contract.from_abi("V1_ITOKEN_MIGRATOR", address=proxy, abi=ITokenV1Migrator.abi)
# print("iETH_OLD.tokenPrice()", iETH_OLD.tokenPrice())
# print("iETH.tokenPrice()", iETH.tokenPrice())
# V1_ITOKEN_MIGRATOR.setTokenPrice(iETH_OLD, iETH_OLD.tokenPrice(), iETH,  iETH.tokenPrice(), {'from': deployer})
# assert int(V1_ITOKEN_MIGRATOR.iTokenPrices(iETH_OLD)/1e14) == int(1e18 * iETH_OLD.tokenPrice() / iETH.tokenPrice()/1e14)
# V1_ITOKEN_MIGRATOR.transferOwnership(DAOGuardiansMultisig,{'from': deployer})
#
# #Replace implementation, to disable mint, burn borrow, trade (previous impl: 0x55742b81b22ced4806e0ef6545e358643726d128)
# itokenImpl = LoanTokenLogicV4.deploy({'from': accounts[0]})
# iETH_OLD_PROXY = Contract.from_abi("iETH_OLD", iETH_OLD, LoanToken.abi)
# iETH_OLD_PROXY.setTarget(itokenImpl, {'from': DAOGuardiansMultisig})
#
# balance = WETH.balanceOf(iETH_OLD)
# print("Migrating amount: ", balance)
# iETH_OLD.setApprovals(WETH, iETH, balance, {'from': DAOGuardiansMultisig})
# iETH_OLD.migrate(iETH, V1_ITOKEN_MIGRATOR, balance, {'from': DAOGuardiansMultisig})

######### test

holder = "0x4ec0a158f5d5563fc92a935e460ca3db49475dc4"
v1BalanceBefore = iETH_OLD.balanceOf(holder)
v2BalanceBefore = iETH.balanceOf(holder)
tokenBalanceBefore = WETH.balanceOf(holder)
iETH_OLD = Contract.from_abi("iETH_OLD", "0x77f973FCaF871459aa58cd81881Ce453759281bC", interface.IToken.abi)
iETH_OLD.burn(holder, 2e18, {'from': holder})
assert history[-1].status.name == 'Reverted'
iETH_OLD.approve(V1_ITOKEN_MIGRATOR, v1BalanceBefore, {'from': holder})
V1_ITOKEN_MIGRATOR.migrate(iETH_OLD, {'from': holder})
v1BalanceAfter = iETH_OLD.balanceOf(holder)
v2BalanceAfter = iETH.balanceOf(holder)
tokenBalanceAfter = WETH.balanceOf(holder)
assert v1BalanceAfter == 0
assert v2BalanceAfter > v2BalanceBefore
assert int(v2BalanceAfter/1e15) == int(V1_ITOKEN_MIGRATOR.iTokenPrices(iETH_OLD) * v1BalanceBefore/1e18/1e15)
assert tokenBalanceBefore == tokenBalanceAfter

iETH.burn(holder, v2BalanceAfter, {'from': holder})
tokenBalanceAfter = WETH.balanceOf(holder)
assert tokenBalanceBefore < tokenBalanceAfter