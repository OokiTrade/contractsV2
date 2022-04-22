from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]
gasPrice = Wei("13 gwei")
index = deployer.nonce

## TickMathV1 deploy
tickMath = TickMathV1.deploy({"from": deployer, "gas_price": gasPrice, "nonce": 189, "required_confs": 0})
index = index + 1
## ProtocolPausableGuardian
guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 190, "required_confs": 0})
#guardianImpl = Contract.from_abi("guardianImpl", address="0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", abi=ProtocolPausableGuardian.abi)
index = index + 1
## LoanSettings require mathTick
# settingsImpl = LoanSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# #settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)
# index = index + 1
## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 191, "required_confs": 0})
#openingsImpl = Contract.from_abi("openingsImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanOpenings.abi)
index = index + 1
# ## LoanMaintenance require mathTick
# maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 192, "required_confs": 0})
# #maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)
index = index + 1
## LoanMigration
migrationImpl = LoanMigration.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 192, "required_confs": 0})
#migrationImpl = Contract.from_abi("maintenaceImpl", address="0x4416883645E26EB91D62EB1B9968f925d8388C44", abi=LoanMigration.abi)
index = index + 1
# ## LoanMaintenance require mathTick
# maintenaceImpl = LoanMaintenance.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# #maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)
# index = index + 1
# ## LoanClosings
# closingImpl = LoanClosings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# #closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)
# index = index + 1
## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 193, "required_confs": 0})
#swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)
index = index + 1
## ProtocolSettings
protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 194, "required_confs": 0})
#protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", abi=ProtocolSettings.abi)
index = index + 1
print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 195, "required_confs": 0})
index = index + 1
univ2 = SwapsImplUniswapV2_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 196, "required_confs": 0})
index = index + 1
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 197, "required_confs": 0})
index = index + 1
# dex_record.setDexID(univ2.address, {'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# dex_record.setDexID(univ3.address, {'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# dex_record.transferOwnership(TIMELOCK, {'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#dex_record = Contract.from_abi("dex_record", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=DexRecords.abi)


# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 198, "required_confs": 0})
index = index + 1
#CUI = Contract.from_abi("CurvedInterestRate", address="0xDbf57A4Cf3d460D8e379dd9fAfbc7A62Af5e653e", abi=CurvedInterestRate.abi)

# Deploy LoanTokenSettings
settngs = LoanTokenSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 199, "required_confs": 0})
#settngs = Contract.from_abi("settngs", address="0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", abi=LoanTokenSettings.abi)
index = index + 1
# Deploy LoanTokenSettingsLowerAdmin
settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 200, "required_confs": 0})
#settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenSettingsLowerAdmin.abi)
index = index + 1
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 201, "required_confs": 0})
#loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53", abi=LoanTokenLogicStandard.abi)
index = index + 1
loanTokenLogicWeth = LoanTokenLogicWeth.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 202, "required_confs": 0})
#loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)
index = index + 1

ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": gasPrice, "nonce": 203, "required_confs": 0})

index = index + 1
helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": gasPrice, "nonce": 204, "required_confs": 0})




# >>> exec(open("./scripts/dao-proposals/OOIP-11-loan-migration/before_proposal.py").read())
# Transaction sent: 0xe910f1193fd05d409f79b1804e585d93fc64443f90011c1568b5cec1cf39d5d5
#   Gas price: 13.0 gwei   Gas limit: 501806   Nonce: 189
# Transaction sent: 0x5343c27bc046873e714d3b96db7fd3b699641daea099d265990b0c3ecb2ade6a
#   Gas price: 13.0 gwei   Gas limit: 1740128   Nonce: 190
#   File "<console>", line 1, in <module>
#   File "<string>", line 16, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 509, in deploy
#     data = contract.deploy.encode_input(*args)
#   File "brownie/network/contract.py", line 556, in encode_input
#     raise UndeployedLibrary(
# UndeployedLibrary: Contract requires 'TickMathV1' library, but it has not been deployed yet
# >>> tickMath = TickMathV1.deploy({"from": deployer, "gas_price": Wei("20 gwei"), "nonce": 189, "required_confs": 0})
# Transaction sent: 0xedbcba00aff725d9acd53d3a405706d9b9ec85cebd0f0d3ec5a742a4db0898f2
#   File "<console>", line 1, in <module>. |
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 510, in deploy
#     receipt, exc = self._make_transaction(
#   File "brownie/network/account.py", line 744, in _make_transaction
#     response = self._transact(tx, allow_revert)  # type: ignore
#   File "brownie/network/account.py", line 994, in _transact
#     response = self._provider.make_request("account_signTransaction", [tx])
#   File "web3/providers/ipc.py", line 252, in make_request
#     timeout.sleep(0)
#   File "web3/_utils/threads.py", line 89, in sleep
#     self.check()
#   File "web3/_utils/threads.py", line 82, in check
#     raise self
# Timeout: 120 seconds
# >>>



# second log
# >>> accounts.connect_to_clef()
# >>> gasPrice = Wei("13 gwei")
# >>> deployer = accounts[2]
# >>> deployer
# <ClefAccount '0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6'>
# >>> settingsImpl = LoanSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 191, "required_confs": 0})
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 509, in deploy
#     data = contract.deploy.encode_input(*args)
#   File "brownie/network/contract.py", line 556, in encode_input
#     raise UndeployedLibrary(
# UndeployedLibrary: Contract requires 'TickMathV1' library, but it has not been deployed yet
# >>> openingsImpl = LoanOpenings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 191, "required_confs": 0})
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 510, in deploy
#     receipt, exc = self._make_transaction(
#   File "brownie/network/account.py", line 752, in _make_transaction
#     exc = VirtualMachineError(e)
#   File "brownie/exceptions.py", line 93, in __init__
#     raise ValueError(str(exc)) from None
# ValueError: reply lacks signature
# >>> openingsImpl = LoanOpenings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 191, "required_confs": 0})
# Transaction sent: 0xb4dc6ecda685e31d9896ec20d1e9df0b912ed96a68fe1d127cc25e5b8e852718
#   Gas price: 13.0 gwei   Gas limit: 4953567   Nonce: 191
# >>> maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 192, "required_confs": 0})
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 509, in deploy
#     data = contract.deploy.encode_input(*args)
#   File "brownie/network/contract.py", line 556, in encode_input
#     raise UndeployedLibrary(
# UndeployedLibrary: Contract requires 'TickMathV1' library, but it has not been deployed yet
# >>> migrationImpl = LoanMigration.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 192, "required_confs": 0})
# Transaction sent: 0x29f57f6100c0e87c746ffa5278d2f2f8621f34e8e4ace70f0027f0d7bf461010
#   Gas price: 13.0 gwei   Gas limit: 2616785   Nonce: 192
# >>> maintenaceImpl = LoanMaintenance.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 192, "required_confs": 0})
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 509, in deploy
#     data = contract.deploy.encode_input(*args)
#   File "brownie/network/contract.py", line 556, in encode_input
#     raise UndeployedLibrary(
# UndeployedLibrary: Contract requires 'TickMathV1' library, but it has not been deployed yet
# >>> closingImpl = LoanClosings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 193, "required_confs": 0})
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 509, in deploy
#     data = contract.deploy.encode_input(*args)
#   File "brownie/network/contract.py", line 556, in encode_input
#     raise UndeployedLibrary(
# UndeployedLibrary: Contract requires 'TickMathV1' library, but it has not been deployed yet
# >>> swapsImpl = SwapsExternal.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})swapsImpl = SwapsExternal.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 193, "required_confs": 0})       

# KeyboardInterrupt
# >>> swapsImpl = SwapsExternal.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 193, "required_confs": 0})
# Transaction sent: 0x622db076b206de7998fda2c22bd6ea2c85382c6592708494126b4b7571489786
#   Gas price: 13.0 gwei   Gas limit: 3613593   Nonce: 193
# >>> protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 194, "required_confs": 0})
# Transaction sent: 0x82b6140cfe416cd64e50ae9b70696244d727018a3d86a91c9f9ebdc768ef23cb
#   Gas price: 13.0 gwei   Gas limit: 4031437   Nonce: 194
# >>> dex_record = DexRecords.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 195, "required_confs": 0})
# Transaction sent: 0x07f1fe2d9676e747675aaa245d0f00b5075a0fd40e00cd4af079a1dc812999e4
#   Gas price: 13.0 gwei   Gas limit: 456564   Nonce: 195
# >>> univ2 = SwapsImplUniswapV2_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 196, "required_confs": 0})
# Transaction sent: 0x53804e3ad1ae3e39a23b8a332bbad7d4b2d2eed6f7ee36c269dc174f7609f4b2
#   Gas price: 13.0 gwei   Gas limit: 2974843   Nonce: 196
# >>> univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 197, "required_confs": 0})
# Transaction sent: 0x9a46826e7cc253518b1a9948d445050675fc3224d82474cd5e6ce556a1c8dea4
#   Gas price: 13.0 gwei   Gas limit: 3232825   Nonce: 197
# >>> CUI = CurvedInterestRate.deploy({'from':deployer, "gas_price": gasPrice, "nonce": 198, "required_confs": 0})
# Transaction sent: 0xc0042a098d8736fc64b336c82d02863bee5aef77adc167a1f8b6062f60c7c489
#   Gas price: 13.0 gwei   Gas limit: 899310   Nonce: 198
# >>> settngs = LoanTokenSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 199, "required_confs": 0})
# Transaction sent: 0x37b5c0d46d39681dcd729ff41312037526fe08716b75581276759f4ab289b7e4
#   Gas price: 13.0 gwei   Gas limit: 1806042   Nonce: 199
# >>> settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 200, "required_confs": 0})                                                                                                 

# KeyboardInterrupt
# >>> gasPrice
# 13000000000
# >>> settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 200, "required_confs": 0})
# Transaction sent: 0xf6c76bbca5df8ac9d713068941ba6febacc890f98fb6a9dd1c5a4e9034e960bf
#   Gas price: 13.0 gwei   Gas limit: 1649366   Nonce: 200
# >>> loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 201, "required_confs": 0})
# Transaction sent: 0x1ba4a50d4a650211c0d939139000e288290d14b093316c72e56b9c0dfcc7296b
#   Gas price: 13.0 gwei   Gas limit: 4682302   Nonce: 201
# >>> loanTokenLogicWeth = LoanTokenLogicWeth.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 202, "required_confs": 0})
# Transaction sent: 0xc0def2990802b970eef7c9541bf93d642b0251d45715e890fe4543de85db8c6a
#   Gas price: 13.0 gwei   Gas limit: 4852390   Nonce: 202
# >>> ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": gasPrice, "nonce": 203, "required_confs": 0})
# Transaction sent: 0xd02d20dd486ba3c4109550530ae1fd6743e421df77baa8ae82f92e86802f1dcb
#   Gas price: 13.0 gwei   Gas limit: 734708   Nonce: 203
# >>> helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": gasPrice, "nonce": 204, "required_confs": 0})
# Transaction sent: 0x47914cc379b26a55afda2dc4c0f0e6decedae03c9f22ae047814280a80f1fe89
#   Gas price: 13.0 gwei   Gas limit: 1781605   Nonce: 204
