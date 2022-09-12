from brownie import *

exec(open("./scripts/env/set-optimism.py").read())
deployer = accounts[0]

MINIMAL_RATES = {
    "iETH":   0.1e18,
    "iBTC":   0.1e18,
    "iUSDC":  0.8e18,
    "iUSDT":  0.8e18,
    "iDAI":   0.8e18,
    "iOP":    0.1e18,
    "iFRAX":  0.8e18
}

cui = CurvedInterestRate.deploy({'from': deployer})
cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, 0.1e18, 0.1e18), ZERO_ADDRESS, {"from": deployer}) # default across all

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    print("itoken", existingIToken.symbol(), assetPair[0])
    cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(existingIToken.symbol()), MINIMAL_RATES.get(existingIToken.symbol())), existingIToken, {"from": deployer})


cui.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
cui.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

call3Sets = []
for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    call = existingIToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(cui))
    target = existingIToken.address
    failure = False
    call3Sets.append((target, failure, call))

print(interface.IMulticall3("0xcA11bde05977b3631167028862bE2a173976CA11").aggregate3.encode_input(call3Sets))

