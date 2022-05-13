from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-bsc.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x82cedB275BF513447300f670708915F99f085FD6"
safe = ApeSafe(multisig)

calldata_set = []
gnosisTransactions = []
def migrate(iToken, migrator):
    calldata_set = []
    gnosisTransactions = []
    end = migrator.getLoanCount(iToken)
    count = 3
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        migrator.migrateLoans(iToken,count * x, count, {'from': multisig})
        addToCalldataSet(calldata_set,migrator.address,migrator.migrateLoans.encode_input(iToken, count * x, count))

    #generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
    #previewGnosisTransactions(safe,gnosisTransactions)


supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    migrate(existingIToken, migrator)