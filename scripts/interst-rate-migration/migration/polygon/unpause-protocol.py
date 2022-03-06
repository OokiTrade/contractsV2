from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
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
generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
#previewGnosisTransactions(safe,gnosisTransactions)
