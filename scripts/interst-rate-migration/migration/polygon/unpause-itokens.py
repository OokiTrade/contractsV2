from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
safe = ApeSafe(multisig)

pauseSignatures=[
    iMATIC.mint.signature,
    iMATIC.burn.signature,
    iMATIC.flashBorrow.signature,
    iMATIC.marginTrade.signature
]


calldata_set = []
gnosisTransactions = []
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=PausableGuardian.abi)
    existingIToken.pause(pauseSignatures, {'from': multisig})
    addToCalldataSet(calldata_set,existingIToken.address, BZX.pause.encode_input(protocolPauseSignatures))

generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
#previewGnosisTransactions(safe,gnosisTransactions)