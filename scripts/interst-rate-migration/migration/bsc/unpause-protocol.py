from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-bsc.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x82cedB275BF513447300f670708915F99f085FD6"
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
addToCalldataSet(calldata_set,BZX.address, BZX.unpause.encode_input(protocolPauseSignatures))
BZX.unpause(protocolPauseSignatures, {'from': multisig})
print("unPauseProtocol:: Submitting transaction to gnosis")
print("generated ", len(calldata_set), " transactions")
#generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
#previewGnosisTransactions(safe,gnosisTransactions)
