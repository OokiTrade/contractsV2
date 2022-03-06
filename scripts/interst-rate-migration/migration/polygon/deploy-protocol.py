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
print("Update BZX modules")

## ProtocolPausableGuardian
guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer})
## LoanSettings
settingsImpl = LoanSettings.deploy({'from': deployer})
## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer})
## LoanMaintenance
maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer})
## LoanMigration
migrationImpl = LoanMigration.deploy({'from': deployer})
## LoanMaintenance
maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
## LoanClosings
closingImpl = LoanClosings.deploy({'from': deployer})
## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer})
## ProtocolSettings
protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer})


print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer})
univ2 = SwapsImplUniswapV2_POLYGON.deploy({'from':deployer})
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
dex_record.setDexID(univ2.address, {'from':deployer})
dex_record.setDexID(univ3.address, {'from':deployer})
dex_record.transferOwnership(multisig, {'from': deployer})


addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(settingsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(guardianImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(openingsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenace2Impl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(migrationImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenaceImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(closingImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(swapsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(protocolsettingsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.setSwapsImplContract.encode_input(dex_record.address))

BZX.replaceContract(settingsImpl.address, {'from': multisig})
BZX.replaceContract(guardianImpl.address, {'from': multisig})
BZX.replaceContract(openingsImpl.address, {'from': multisig})
BZX.replaceContract(maintenace2Impl.address, {'from': multisig})
BZX.replaceContract(migrationImpl.address, {'from': multisig})
BZX.replaceContract(maintenaceImpl.address, {'from': multisig})
BZX.replaceContract(closingImpl.address, {'from': multisig})
BZX.replaceContract(swapsImpl.address, {'from': multisig})
BZX.replaceContract(protocolsettingsImpl.address, {'from': multisig})
BZX.setSwapsImplContract(dex_record.address, {'from':multisig})

generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
# previewGnosisTransactions(safe,gnosisTransactions)