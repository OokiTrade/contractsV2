from distutils.command.install_egg_info import safe_version
from brownie import *
from ape_safe import ApeSafe
from gnosis.safe import SafeOperation
exec(open("./scripts/env/set-optimism.py").read())
#accounts.load('deploy')
#deployer = accounts[0]
safe = ApeSafe(GUARDIAN_MULTISIG)

MINIMAL_RATES = {
    "iETH":   0.1e18,
    "iBTC":   0.1e18,
    "iUSDC":  0.8e18,
    "iUSDT":  0.8e18,
    "iDAI":   0.8e18,
    "iOP":    0.1e18,
    "iFRAX":  0.8e18
}

#cui = CurvedInterestRate.deploy({'from': deployer}, publish_source=True)
cui = CurvedInterestRate.at("0x100f9EC4E0085d8f469500F66370f8dc64e1F670")
#CurvedInterestRate.publish_source(cui)
#cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, 0.1e18, 0.1e18), ZERO_ADDRESS, {"from": deployer}) # default across all

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    print("itoken", existingIToken.symbol(), assetPair[0])
#    cui.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(existingIToken.symbol()), MINIMAL_RATES.get(existingIToken.symbol())), existingIToken, {"from": deployer})




#cui.changeGuardian(GUARDIAN_MULTISIG, {"from": deployer})
#cui.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})

call3Sets = []
call = ""
for assetPair in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=assetPair[0], abi=interface.IToken.abi)
    call = existingIToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(cui))
    target = existingIToken.address
    failure = False
    call3Sets.append((target, failure, call))
    print(target)

print(call)
txn = MULTICALL3.aggregate3.encode_input(call3Sets)
sTxn = safe.build_multisig_tx(MULTICALL3.address, 0, txn, SafeOperation.DELEGATE_CALL.value, safe_nonce=8, safe_version="1.3.0")
safe.sign_with_frame(sTxn)
safe.post_transaction(sTxn)

