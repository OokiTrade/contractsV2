#!/usr/bin/python3

# Setup specific addresses / wallets for testing
# Requires previous run of fork_setup script

mintAddresses = ["0x81b9284090501255C3a271c90100744Da99CC828", "0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", "0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", "0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", "0xB78A81cd4FB3d727CD267d773491F5fC43BB3929"]
for user in mintAddresses:
    print("mining for user:", user)
    BZRX.transfer(user, 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
    vBZRX.transfer(user, 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
    iBZRX.transfer(user, 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})
    BPT.transfer(user, 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
# BZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
# BZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
# BZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})


# print("mining some vBZRX")
# #0x95beec2457838108089fcd0e059659a4e60b091a
# vBZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
# vBZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})
# vBZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0x95beec2457838108089fcd0e059659a4e60b091a"})

# print("mining some iBZRX")
# #0xfe36046f6193d691f99e2c90153003f8938cfc41
# iBZRX.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})
# iBZRX.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})
# iBZRX.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 1000e18, {'from': "0xfe36046f6193d691f99e2c90153003f8938cfc41"})

# print("mining some BPT")
# # 0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7
# BPT.transfer("0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
# BPT.transfer("0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})
# BPT.transfer("0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", 100e18, {'from': "0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7"})

# print("pre approve staking")
# accounts[0].transfer(to="0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f", amount=Wei('1 ether'))
# accounts[0].transfer(to="0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3", amount=Wei('1 ether'))



# BZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# vBZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# iBZRX.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})
# BPT.approve(staking, 2**256-1, {'from': '0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f'})

# BZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# vBZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# iBZRX.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})
# BPT.approve(staking, 2**256-1, {'from': '0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3'})



# Run command below
# exec(open("./scripts/staking-fork.py").read())
# brownie networks add Ethereum staging chainid=1 host=http://35.174.43.93:5458

# ganache-cli --accounts 10 --hardfork istanbul --fork https://eth-mainnet.alchemyapi.io/v2/1-sHvdVH_hHp9jvOiVp4LqqXg0_sGhPK --gasLimit 12000000 --mnemonic brownie --port 8545 --chainId 1 -h 0.0.0.0 -v -u "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
# https://eth-mainnet.alchemyapi.io/v2/Cim1KnSYjNWTExhMWHMpewQUyatTbmfE

# ganache-cli --accounts 10 --hardfork istanbul --fork https://eth-mainnet.alchemyapi.io/v2/Cim1KnSYjNWTExhMWHMpewQUyatTbmfE --gasLimit 12000000 --mnemonic brownie --port 5458 --chainId 1 -h 0.0.0.0 \
#     -u 0xB7F72028D9b502Dc871C444363a7aC5A52546608\
#     -u 0xb72b31907c1c95f3650b64b2469e08edacee5e8f\
#     -u 0x56d811088235F11C8920698a204A5010a788f4b3\
#     -u 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157\
#     -u 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7\
#     -u 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490\
#     -u 0xe26A220a341EAca116bDa64cF9D5638A935ae629\
#     -u 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8\
#     -u 0x95beec2457838108089fcd0e059659a4e60b091a\
#     -u 0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe\
#     -u 0xfe36046f6193d691f99e2c90153003f8938cfc41\
#     -u 0xF69D58D756f2c9b2D37fB50a62736E92253F1c7f\
#     -u 0x42a3FDad947807f9FA84B8c869680A3B7A46bEe7\
#     -u 0xddAd23Dd65ac23f3e6b4E2706575A90D50349Eb3

