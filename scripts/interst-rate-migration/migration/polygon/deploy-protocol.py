from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())


itokenPrices = {}
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    itokenPrices[existingIToken.address] = existingIToken.tokenPrice()

#deployer = accounts[0]
deployer = accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
safe = ApeSafe(multisig)

calldata_set = []
gnosisTransactions = []
print("Update BZX modules")

## ProtocolPausableGuardian
#guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer})
guardianImpl = Contract.from_abi("guardianImpl", address="0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", abi=ProtocolPausableGuardian.abi)

## LoanSettings
#settingsImpl = LoanSettings.deploy({'from': deployer})
settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)

## LoanOpenings
#openingsImpl = LoanOpenings.deploy({'from': deployer})
openingsImpl = Contract.from_abi("openingsImpl", address="0x2767078d232f50A943d0BA2dF0B56690afDBB287", abi=LoanOpenings.abi)

## LoanMaintenance
#maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer})
maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)

## LoanMigration
#migrationImpl = LoanMigration.deploy({'from': deployer})
migrationImpl = Contract.from_abi("maintenaceImpl", address="0x650980C7CB878629Bda2C33828A8F729B9B8635c", abi=LoanMigration.abi)

## LoanMaintenance
#maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)

## LoanClosings
#closingImpl = LoanClosings.deploy({'from': deployer})
closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)

## SwapsExternal
#swapsImpl = SwapsExternal.deploy({'from': deployer})
swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)

## ProtocolSettings
#protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer})
protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", abi=ProtocolSettings.abi)


print("Deploying Dex Selector and Implementations")
#dex_record = DexRecords.deploy({'from':deployer})
#univ2 = SwapsImplUniswapV2_POLYGON.deploy({'from':deployer})
#univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
#dex_record.setDexID(univ2.address, {'from':deployer})
#dex_record.setDexID(univ3.address, {'from':deployer})
#dex_record.transferOwnership(multisig, {'from': deployer})
dex_record = Contract.from_abi("dex_record", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=DexRecords.abi)


#
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(settingsImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(guardianImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(openingsImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenace2Impl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(migrationImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenaceImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(closingImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(swapsImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(protocolsettingsImpl.address))
# addToCalldataSet(calldata_set,BZX.address, BZX.setSwapsImplContract.encode_input(dex_record.address))

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

# generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
# previewGnosisTransactions(safe,gnosisTransactions)
