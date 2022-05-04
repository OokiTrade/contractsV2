from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())
safe = ApeSafe(GUARDIAN_MULTISIG)

calldata_set = []
gnosisTransactions = []
USDT.transfer(BZX, 1000e6, {'from': '0x61f2f664fec20a2fc1d55409cfc85e1baeb943e2'})
def migrate(iToken, migrator):
    end = migrator.getLoanCount(iToken)
    count = 20
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        addToCalldataSet(calldata_set,migrator.address,migrator.migrateLoans.encode_input(iToken, count * x, count))
        #migrator.migrateLoans(iToken,count * x, count, {'from': GUARDIAN_MULTISIG})

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    if(existingIToken == iOOKI):
        continue
    print("Migrate: ", existingIToken.symbol())
    migrate(existingIToken, migrator)

protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
    BZX.liquidate.signature,
    BZX.depositCollateral.signature,
    BZX.withdrawCollateral.signature,
    BZX.settleInterest.signature
]
print("unpause protocol")
addToCalldataSet(calldata_set,migrator.address,BZX.unpause.encode_input(protocolPauseSignatures))
#BZX.unpause(protocolPauseSignatures, {'from': GUARDIAN_MULTISIG})
#generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
