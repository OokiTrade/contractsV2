from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]#accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x02c6819c2cb8519aB72fD1204A8A0992b5050C6e"
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
