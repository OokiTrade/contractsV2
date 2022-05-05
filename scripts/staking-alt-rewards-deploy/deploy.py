exec(open("./scripts/env/set-eth.py").read())
gasPrice = Wei("31 gwei")
deployer = accounts[2]

admImpl = AdminSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 215, "required_confs": 0})
stakingImpl = StakeUnstake.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 216, "required_confs": 0})



# # log
# >>> admImpl = AdminSettings.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 215, "required_confs": 0})
# Transaction sent: 0xf75cbec7426e0a6e5b19a7073b4e5c973b04e50aabde050e6c1881ce20679f3c
#   Gas price: 31.0 gwei   Gas limit: 2358518   Nonce: 215
# >>> stakingImpl = StakeUnstake.deploy({'from': deployer, "gas_price": gasPrice, "nonce": 216, "required_confs": 0})
# Transaction sent: 0x4e3032bc05f8fe16a6ac6d8911ace0be43de62a7795138ecbc0e29352ad7b6f9
#   Gas price: 31.0 gwei   Gas limit: 4489158   Nonce: 216