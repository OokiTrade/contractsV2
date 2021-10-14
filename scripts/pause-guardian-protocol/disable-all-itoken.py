exec(open("./scripts/env/set-eth.py").read())

BZX_GUARDIAN_MULTISIG = accounts.load("BZX_GUARDIAN_MULTISIG")

# this will indirectly disable all functions on the iToken side:
# 1. mint
# 2. burn
# 3. marginTrade
# 4. borrow
# 5. flashBorrow

BZX.toggleFunctionPause(BZX.withdrawAccruedInterest.signature, {"from": BZX_GUARDIAN_MULTISIG, "priority_fee", Wei("100 gwei")})
