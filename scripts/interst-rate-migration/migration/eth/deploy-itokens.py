from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]#accounts.load("0xF6c5B9c0B57590A5be6f16380D68eAC6fd9d0Fac")
multisig = "0x02c6819c2cb8519aB72fD1204A8A0992b5050C6e"
safe = ApeSafe(multisig)

def replaceIToken(calldata_set,settings, itoken, token, loanTokenLogicStandard):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    print("iToken: ", iToken.name())

    print("setTarget", loanTokenLogicStandard)
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': TIMELOCK})
    addToCalldataSet(calldata_set,iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))

    if(token.allowance(iToken, BZX)==0):
        calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
        print("initialize::calldata", calldata)
        print("initialize", iToken.name())
        iToken.updateSettings(settings, calldata, {"from": TIMELOCK})
        addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(calldata_set,settngsLowerAdmin, iToken, CUI):
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    iToken.updateSettings(settngsLowerAdmin, calldata,{"from": TIMELOCK})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settngsLowerAdmin.address, calldata))



gas_used['deploy_itoken'] = {
    'start':  len(history),
    'used': 0
}
calldata_set = []
gnosisTransactions = []

# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer})
#CUI = Contract.from_abi("CurvedInterestRate", address="0xDbf57A4Cf3d460D8e379dd9fAfbc7A62Af5e653e", abi=CurvedInterestRate.abi)

# Deploy LoanTokenSettings
settngs = deployer.deploy(LoanTokenSettings)
#settngs = Contract.from_abi("settngs", address="0x2D2c97Fdad02FAd635aEfCD311d123Da9607A6f2", abi=LoanTokenSettings.abi)
#settngs.transferOwnership(multisig, {'from': deployer})

# Deploy LoanTokenSettingsLowerAdmin
settngsLowerAdmin = deployer.deploy(LoanTokenSettingsLowerAdmin)
#settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x4eFb3D5f996F1896948504217a52B2ED15E86926", abi=LoanTokenSettingsLowerAdmin.abi)
#settngsLowerAdmin.transferOwnership(multisig, {'from': deployer})

loanTokenLogicStandard = LoanTokenLogicStandard.deploy(multisig, {'from': deployer})
#loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x272d1Fb16ECbb5ff8042Df92694791b506aA3F53", abi=LoanTokenLogicStandard.abi)

loanTokenLogicWeth = LoanTokenLogicWeth.deploy(multisig, {'from': deployer}).address
#loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenLogicWeth.abi)

gas_used['deploy_itoken']['end'] = len(history)
gas_used['setup_itoken'] = {
    'start':  len(history),
    'used': 0
}
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    if(existingIToken == iOOKI):
        continue
    if(existingIToken == iETH):
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
gas_used['setup_itoken']['end'] = len(history)

