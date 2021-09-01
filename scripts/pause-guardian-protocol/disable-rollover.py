exec(open("./scripts/env/set-eth.py").read())

BZX_GUARDIAN_MULTISIG = accounts.load("BZX_GUARDIAN_MULTISIG")

BZX.toggleFunctionPause(BZX.rollover.signature, {"from": BZX_GUARDIAN_MULTISIG, "priority_fee", Wei("100 gwei")})
