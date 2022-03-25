from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]#accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
safe = ApeSafe(multisig)

protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
    BZX.liquidate.signature,
    BZX.depositCollateral.signature,
    BZX.withdrawCollateral.signature,
    BZX.settleInterest.signature
]


calldata_set = []
gnosisTransactions = []
addToCalldataSet(calldata_set,BZX.address, BZX.pause.encode_input(protocolPauseSignatures))
BZX.pause(protocolPauseSignatures, {'from': multisig})

print("pauseProtocol:: Submitting transaction to gnosis")
print("generated ", len(calldata_set), " transactions")
#generateGnosisTransactions(safe,calldata_set, gnosisTransactions, 81)
#previewGnosisTransactions(safe,gnosisTransactions)