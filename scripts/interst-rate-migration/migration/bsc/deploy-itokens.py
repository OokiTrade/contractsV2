from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-bsc.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x82cedB275BF513447300f670708915F99f085FD6"
safe = ApeSafe(multisig)


def replaceIToken(calldata_set,settings, itoken, token, logic):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken.name()", iToken)
    print("setTarget", logic)
    iTokenProxy.setTarget(logic, {'from': multisig})
    addToCalldataSet(calldata_set,iTokenProxy.address, iTokenProxy.setTarget.encode_input(logic))

    calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
    print("initialize::calldata", calldata)
    print("initialize", iToken.name())
    iToken.updateSettings(settings, calldata, {"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(calldata_set,settngsLowerAdmin, iToken, CUI):
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    iToken.updateSettings(settngsLowerAdmin, calldata,{"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settngsLowerAdmin.address, calldata))


calldata_set = []
gnosisTransactions = []

# Deploy CurvedInterestRate

#CUI = CurvedInterestRate.deploy({'from':deployer})
CUI = Contract.from_abi("CurvedInterestRate", address="0xF082901C5d59846fbFC699FBB87c6D0f538f099d", abi=CurvedInterestRate.abi)

# Deploy LoanTokenSettings
#settngs = LoanTokenSettings.deploy({'from': deployer})
settngs = Contract.from_abi("settngs", address="0x4416883645E26EB91D62EB1B9968f925d8388C44", abi=LoanTokenSettings.abi)
#settngs.transferOwnership(multisig, {'from': deployer})

# Deploy LoanTokenSettingsLowerAdmin
#settngsLowerAdmin = LoanTokenSettingsLowerAdmin.deploy({'from': deployer})
settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", abi=LoanTokenSettingsLowerAdmin.abi)
#settngsLowerAdmin.transferOwnership(multisig, {'from': deployer})

#loanTokenLogicStandard = LoanTokenLogicStandard.deploy(multisig, {'from': deployer}).address
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenLogicStandard.abi)

#loanTokenLogicWeth = LoanTokenLogicWeth.deploy(multisig, {'from': deployer}).address
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)

print("Redeploying iToken")
print("settngs", settngs)

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    if(existingIToken == iBNB):
        print("WET logic")
        replaceIToken(calldata_set, settngs, existingIToken, existingToken, loanTokenLogicWeth)
    else:
        replaceIToken(calldata_set, settngs, existingIToken, existingToken, loanTokenLogicStandard)
    print("Update curve", existingIToken)
    updateMarginSettings(calldata_set,settngsLowerAdmin, existingIToken, CUI)
print("deploy:: Submitting transaction to gnosis")
print("generated ", len(calldata_set), " transactions")

#generateGnosisTransactions(safe,calldata_set, gnosisTransactions, 63)
#previewGnosisTransactions(safe,gnosisTransactions)

