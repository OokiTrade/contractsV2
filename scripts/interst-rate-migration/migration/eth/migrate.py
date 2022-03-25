from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]#accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
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
        migrator.migrateLoans(iToken,count * x, count, {'from': multisig})
        addToCalldataSet(calldata_set,migrator.address,migrator.migrateLoans.encode_input(iToken, count * x, count))

    #generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
    #previewGnosisTransactions(safe,gnosisTransactions)

gas_used['migrate_itoken'] = {
    'start':  len(history),
    'used': 0
}
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    if(existingIToken == iOOKI):
        continue

    migrate(existingIToken, migrator)
gas_used['migrate_itoken']['end'] = len(history)

for x in ['deploy', 'replaceImpl', 'deploy_itoken', 'setup_itoken', 'migrate_itoken']:
    for i in range(gas_used[x]['start'],gas_used[x]['end']):
        gas_used[x]['used'] = gas_used[x]['used'] + history[-1 * (i+1)].gas_used
