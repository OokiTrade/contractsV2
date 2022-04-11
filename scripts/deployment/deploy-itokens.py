from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
safe = ApeSafe(GUARDIAN_MULTISIG)


def replaceIToken(calldata_set, itoken, loanTokenLogicStandard):
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken: ", iToken.name())

    print("setTarget", loanTokenLogicStandard)
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': GUARDIAN_MULTISIG})
    addToCalldataSet(calldata_set,iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))
    return iToken

calldata_set = []
gnosisTransactions = []


loanTokenLogicStandard = LoanTokenLogicStandard.deploy(GUARDIAN_MULTISIG, {'from': deployer})
#loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenLogicStandard.abi)

loanTokenLogicWeth = LoanTokenLogicWeth.deploy(GUARDIAN_MULTISIG, {'from': deployer})
#loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)

print("Redeploying iToken")
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    if(existingIToken == iETH):
        print("WET logic")
        replaceIToken(calldata_set, existingIToken, loanTokenLogicWeth)
    else:
        replaceIToken(calldata_set, existingIToken, loanTokenLogicStandard)

#generateGnosisTransactions(safe,calldata_set, gnosisTransactions, 63)
#previewGnosisTransactions(safe,gnosisTransactions)

