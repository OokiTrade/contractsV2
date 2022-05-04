from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
safe = ApeSafe(GUARDIAN_MULTISIG)

USDT.transfer(BZX, 1000e6, {'from': '0x61f2f664fec20a2fc1d55409cfc85e1baeb943e2'})
def migrate(iToken, migrator):
    end = migrator.getLoanCount(iToken)
    count = 10
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        migrator.migrateLoans(iToken,count * x, count, {'from': TIMELOCK})

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
BZX.unpause(protocolPauseSignatures, {'from': GUARDIAN_MULTISIG})