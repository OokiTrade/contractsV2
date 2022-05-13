from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

exec(open("./scripts/env/set-arbitrum.py").read())
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_GUARDIAN_MULTISIG)
deployer = accounts[2]

calldata_set = []
gnosisTransactions = []
print("Update BZX modules")

## LoanSettings
settingsImpl = LoanSettings.deploy({'from': deployer})
#settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)

## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer})
#openingsImpl = Contract.from_abi("openingsImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanOpenings.abi)

## LoanMaintenance
maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer})
#maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)

## LoanMaintenance
maintenaceImpl = LoanMaintenance.deploy({'from': deployer})
#maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)

## LoanClosings
closingImpl = LoanClosings.deploy({'from': deployer})
#closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)

## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer})
#swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)

ookiPriceFeed = OOKIPriceFeed.deploy({'from':accounts[0]})
pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)

#
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(settingsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(openingsImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenace2Impl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(maintenaceImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(closingImpl.address))
addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(swapsImpl.address))
addToCalldataSet(calldata_set,BZX.address, pricefeeds.setPriceFeed.encode_input([OOKI.address],[ookiPriceFeed.address]))

pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed],{'from':GUARDIAN_MULTISIG})
BZX.replaceContract(settingsImpl.address, {'from': GUARDIAN_MULTISIG})
BZX.replaceContract(openingsImpl.address, {'from': GUARDIAN_MULTISIG})
BZX.replaceContract(maintenace2Impl.address, {'from': GUARDIAN_MULTISIG})
BZX.replaceContract(maintenaceImpl.address, {'from': GUARDIAN_MULTISIG})
BZX.replaceContract(closingImpl.address, {'from': GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl.address, {'from': GUARDIAN_MULTISIG})

#generateGnosisTransactions(safe,calldata_set, gnosisTransactions, 53)
# previewGnosisTransactions(safe,gnosisTransactions)
