from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())

gas_used = {
    'deploy': {
        'start':  len(history),
        'used': 0
    }
}
itokenPrices = {}
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    itokenPrices[existingIToken.address] = existingIToken.tokenPrice()

deployer = accounts[0]#accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
safe = ApeSafe(multisig)

calldata_set = []
gnosisTransactions = []
print("Update BZX modules")

## ProtocolPausableGuardian
guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer})
#guardianImpl = Contract.from_abi("guardianImpl", address="0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", abi=ProtocolPausableGuardian.abi)

## LoanSettings
settingsImpl = LoanSettings.deploy({'from': deployer})
#settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)

## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer})
#openingsImpl = Contract.from_abi("openingsImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanOpenings.abi)

## LoanMaintenance
maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer})
#maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)

## LoanMigration
migrationImpl = LoanMigration.deploy({'from': deployer})
#migrationImpl = Contract.from_abi("maintenaceImpl", address="0x4416883645E26EB91D62EB1B9968f925d8388C44", abi=LoanMigration.abi)

## LoanMaintenance
maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
#maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)

## LoanClosings
closingImpl = LoanClosings.deploy({'from': deployer})
#closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)

## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer})
#swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)

## ProtocolSettings
protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer})
#protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", abi=ProtocolSettings.abi)


print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer})
univ2 = SwapsImplUniswapV2_ETH.deploy({'from':deployer})
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
dex_record.setDexID(univ2.address, {'from':deployer})
dex_record.setDexID(univ3.address, {'from':deployer})
dex_record.transferOwnership(multisig, {'from': deployer})
#dex_record = Contract.from_abi("dex_record", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=DexRecords.abi)
gas_used['deploy']['end'] = len(history)
gas_used['replaceImpl'] = {
    'start':  len(history),
    'used': 0
}
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


history_start_len = len(history)
BZX.replaceContract(settingsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(guardianImpl.address, {'from': TIMELOCK})
BZX.replaceContract(openingsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(maintenace2Impl.address, {'from': TIMELOCK})
BZX.replaceContract(migrationImpl.address, {'from': TIMELOCK})
BZX.replaceContract(maintenaceImpl.address, {'from': TIMELOCK})
BZX.replaceContract(closingImpl.address, {'from': TIMELOCK})
BZX.replaceContract(swapsImpl.address, {'from': TIMELOCK})
BZX.replaceContract(protocolsettingsImpl.address, {'from': TIMELOCK})
BZX.setSwapsImplContract(dex_record.address, {'from':TIMELOCK})

gas_used['replaceImpl']['end'] = len(history)

#generateGnosisTransactions(safe,calldata_set, gnosisTransactions, 53)
# previewGnosisTransactions(safe,gnosisTransactions)

exec(open("./scripts/interst-rate-migration/migration/eth/deploy-itokens.py").read())
exec(open("./scripts/interst-rate-migration/migration/eth/migrate.py").read())
