from brownie import *

exec(open("./scripts/env/set-matic.py").read())
deployer = accounts[0]

MINIMAL_RATES = {
    "iETH":   0.01e18,
    "iBTC":   0.1e18,
    "iLINK":  0.1e18,
    "iUSDC":  0.8e18,
    "iUSDT":  0.8e18,
    "iMATIC":   0.1e18,
}

# cui = CurvedInterestRate.deploy({'from': deployer})
cui = CurvedInterestRate.at("0x0aec8457111de708fac9b48fd1570801b4371cfe")
cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, 0.1e18, 0.01e18), ZERO_ADDRESS, {"from": deployer}) # default across all

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    print("itoken", existingIToken.symbol(), assetPair[0])
    cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(existingIToken.symbol()), MINIMAL_RATES.get(existingIToken.symbol())), existingIToken, {"from": deployer})


cui.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
cui.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    existingIToken.updateSettings(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(cui), {"from": GUARDIAN_MULTISIG})
