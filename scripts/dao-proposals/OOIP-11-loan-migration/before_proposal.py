from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())
deployer = accounts[2]
gasPrice = Wei("13 gwei")
index = deployer.nonce

## TickMathV1 deploy
tickMath = TickMathV1.deploy({"from": deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
index = index + 1
## ProtocolPausableGuardian
guardianImpl = ProtocolPausableGuardian.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#guardianImpl = Contract.from_abi("guardianImpl", address="0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f", abi=ProtocolPausableGuardian.abi)
index = index + 1
## LoanSettings
settingsImpl = LoanSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#settingsImpl = Contract.from_abi("settingsImpl", address="0xBf2c07A86b73c6E338767E8160a24F55a656A9b7", abi=LoanSettings.abi)
index = index + 1
## LoanOpenings
openingsImpl = LoanOpenings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#openingsImpl = Contract.from_abi("openingsImpl", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=LoanOpenings.abi)
index = index + 1
## LoanMaintenance
maintenace2Impl = LoanMaintenance_2.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#maintenace2Impl = Contract.from_abi("maintenace2Impl", address="0x9f46635839F9b5268B1F2d17dE290663aBe0C976", abi=LoanMaintenance_2.abi)
index = index + 1
## LoanMigration
migrationImpl = LoanMigration.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#migrationImpl = Contract.from_abi("maintenaceImpl", address="0x4416883645E26EB91D62EB1B9968f925d8388C44", abi=LoanMigration.abi)
index = index + 1
## LoanMaintenance
maintenaceImpl = LoanMaintenance.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#maintenaceImpl = Contract.from_abi("maintenaceImpl", address="0x0Efc9954ee53f0c3bd19168f34E4c0A927C40334", abi=LoanMaintenance.abi)
index = index + 1
## LoanClosings
closingImpl = LoanClosings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#closingImpl = Contract.from_abi("closingImpl", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanClosings.abi)
index = index + 1
## SwapsExternal
swapsImpl = SwapsExternal.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#swapsImpl = Contract.from_abi("swapsImpl", address="0x5b1d776b65c5160F8f71C45F2472CA8e5a504dE8", abi=SwapsExternal.abi)
index = index + 1
## ProtocolSettings
protocolsettingsImpl = ProtocolSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#protocolsettingsImpl = Contract.from_abi("protocolsettingsImpl", address="0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", abi=ProtocolSettings.abi)
index = index + 1
print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
index = index + 1
univ2 = SwapsImplUniswapV2_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
index = index + 1
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
index = index + 1
# dex_record.setDexID(univ2.address, {'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# dex_record.setDexID(univ3.address, {'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
# dex_record.transferOwnership(TIMELOCK, {'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#dex_record = Contract.from_abi("dex_record", address="0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", abi=DexRecords.abi)


# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
index = index + 1
#CUI = Contract.from_abi("CurvedInterestRate", address="0xDbf57A4Cf3d460D8e379dd9fAfbc7A62Af5e653e", abi=CurvedInterestRate.abi)

# Deploy LoanTokenSettings
settngs = LoanTokenSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#settngs = Contract.from_abi("settngs", address="0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", abi=LoanTokenSettings.abi)
index = index + 1
# Deploy LoanTokenSettingsLowerAdmin
settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenSettingsLowerAdmin.abi)
index = index + 1
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53", abi=LoanTokenLogicStandard.abi)
index = index + 1
loanTokenLogicWeth = LoanTokenLogicWeth.deploy({'from': deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})
#loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)
index = index + 1

ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})

index = index + 1
helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": gasPrice, "nonce": index, "required_confs": 0})




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