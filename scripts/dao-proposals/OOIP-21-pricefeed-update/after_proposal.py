from brownie import *

exec(open("./scripts/env/set-eth.py").read())
BZX.toggleFunctionUnpause(BZX.borrowOrTradeFromPool.signature, {'from': GUARDIAN_MULTISIG})
