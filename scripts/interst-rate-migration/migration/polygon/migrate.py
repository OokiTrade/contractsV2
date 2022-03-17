from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
safe = ApeSafe(multisig)

calldata_set = []
gnosisTransactions = []
def migrate(iToken, migrator):
    calldata_set = []
    gnosisTransactions = []
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
     #   migrator.migrateLoans(iToken,count * x, count, {'from': multisig})
        addToCalldataSet(calldata_set,migrator.address,migrator.migrateLoans.encode_input(iToken, count * x, count))

    generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
    #previewGnosisTransactions(safe,gnosisTransactions)


supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    migrate(existingIToken, migrator)