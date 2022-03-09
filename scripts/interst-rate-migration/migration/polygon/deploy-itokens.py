from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
safe = ApeSafe(multisig)


def replaceIToken(calldata_set,settings, itoken, token, loanTokenLogicStandard):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken: ", iToken.name())

    print("setTarget", loanTokenLogicStandard)
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': multisig})
    addToCalldataSet(calldata_set,iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))

    calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
    print("initialize::calldata", calldata)
    print("initialize", iToken.name())
    iToken.updateSettings(settings, calldata, {"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(calldata_set,settings, iToken, CUI):
    calldata = settings.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    iToken.updateSettings(settings, calldata,{"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))


calldata_set = []
gnosisTransactions = []

# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer})

# Deploy LoanTokenSettings
settngs = deployer.deploy(LoanTokenSettings)
settngs.transferOwnership(multisig, {'from': deployer})
loanTokenLogicStandard = LoanTokenLogicStandard.deploy(multisig, {'from': deployer}).address

print("Redeploying iToken")
print("settngs", settngs)
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    replaceIToken(calldata_set, settngs, existingIToken, existingToken, loanTokenLogicStandard)
    print("Update curve", existingIToken)
    updateMarginSettings(calldata_set,settngs, existingIToken, CUI)
print("deploy:: Submitting transaction to gnosis")
print("generated ", len(calldata_set), " transactions")

generateGnosisTransactions(safe,calldata_set, gnosisTransactions)
#previewGnosisTransactions(safe,gnosisTransactions)

