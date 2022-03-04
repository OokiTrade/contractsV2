from ape_safe import ApeSafe
from brownie.network.contract import Contract
from ape_safe import ApeSafe

exec(open("./scripts/env/set-matic.py").read())
exec(open("./scripts/env/common-functions.py").read())

deployer = accounts[0]
multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"
safe = ApeSafe(multisig)

protocolPauseSignatures=[
    BZX.closeWithDeposit.signature,
    BZX.closeWithSwap.signature,
]

def addToCalldataSet(calldata_set, target, calldata):
    calldata_set.append(
        {
            'target': target,
            'calldata': calldata
        }
    )
    print(calldata_set[-1])

def replaceIToken(calldata_set,settings, itoken, token, loanTokenLogicStandard):
    print("settings", settings)
    iTokenProxy = Contract.from_abi("iProxy", address=itoken.address, abi=LoanToken.abi)
    #iTokenProxy.setTarget(loanTokenLogicStandard, {'from': multisig})
    addToCalldataSet(calldata_set,iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    calldata = settings.initialize.encode_input(token, iToken.name(), iToken.symbol())
    #iToken.updateSettings(settings, calldata, {"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))
    return iToken

def updateMarginSettings(calldata_set,settings, iToken, CUI):
    calldata = settings.setDemandCurve.encode_input(CUI)
    #iToken.updateSettings(settings, calldata,{"from": multisig})
    addToCalldataSet(calldata_set,iToken.address, iToken.updateSettings.encode_input(settings.address, calldata))

def updateBZXModule(calldata_set,BZX, module):
    moduleImpl = module.deploy({'from': deployer})
    #BZX.replaceContract(moduleImpl.address, {'from': multisig})
    addToCalldataSet(calldata_set,BZX.address, BZX.replaceContract.encode_input(moduleImpl.address))

def generateGnosisTransactions(calldata_set,gnosisTransactions):
    for txdata in calldata_set:
        gnosisTx = createGnosisTx(safe, txdata['target'], txdata['calldata'])
        gnosisTransactions.append(gnosisTx)

def previewGnosisTransactions(gnosisTransactions):
    for gnosisTx in gnosisTransactions:
        print(gnosisTx)
        safe.preview(gnosisTx)


def pauseProtocol():
    calldata_set = []
    gnosisTransactions = []
    for signature in protocolPauseSignatures:
        addToCalldataSet(calldata_set,BZX.address, BZX.toggleFunctionPause.encode_input(signature))

    supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
    for tokenAssetPairA in supportedTokenAssetsPairs:
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
        for signature in [existingIToken.mint.signature, existingIToken.burn.signature, existingIToken.borrow.signature, existingIToken.marginTrade.signature]:
            addToCalldataSet(calldata_set,existingIToken.address, existingIToken.toggleFunctionPause.encode_input(signature))

    print("pauseProtocol:: Submitting transaction to gnosis")
    print("generated ", len(calldata_set), " transactions")
    generateGnosisTransactions(calldata_set, gnosisTransactions)
    previewGnosisTransactions(gnosisTransactions)
    assert False

def unpauseProtocol():
    calldata_set = []
    gnosisTransactions = []
    for signature in protocolPauseSignatures:
        addToCalldataSet(calldata_set,BZX.address, BZX.toggleFunctionUnPause.encode_input(signature))

    supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
    for tokenAssetPairA in supportedTokenAssetsPairs:
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
        for signature in [existingIToken.mint.signature, existingIToken.burn.signature, existingIToken.borrow.signature, existingIToken.marginTrade.signature]:
            addToCalldataSet(calldata_set,existingIToken.address, existingIToken.toggleFunctionUnPause.encode_input(signature))

    print("unPauseProtocol:: Submitting transaction to gnosis")
    print("generated ", len(calldata_set), " transactions")
    generateGnosisTransactions(calldata_set, gnosisTransactions)
    previewGnosisTransactions(gnosisTransactions)
    assert False

def deploy():
    calldata_set = []
    gnosisTransactions = []
    print("Update BZX modules")
    ## LoanSettings
    updateBZXModule(calldata_set,BZX, LoanSettings)
    ## LoanOpenings
    updateBZXModule(calldata_set,BZX, LoanOpenings)
    ## LoanMaintenance
    updateBZXModule(calldata_set,BZX, LoanMaintenance_2)
    ## LoanMigration
    updateBZXModule(calldata_set,BZX, LoanMigration)
    ## LoanMaintenance
    updateBZXModule(calldata_set,BZX, LoanMaintenance)
    ## LoanClosings
    updateBZXModule(calldata_set,BZX, LoanClosings)
    ## SwapsExternal
    updateBZXModule(calldata_set,BZX, SwapsExternal)
    ## ProtocolSettings
    updateBZXModule(calldata_set,BZX, ProtocolSettings)

    print("Deploying Dex Selector and Implementations")
    dex_record = DexRecords.deploy({'from':deployer})
    univ2 = SwapsImplUniswapV2_POLYGON.deploy({'from':deployer})
    univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
    dex_record.setDexID(univ2.address, {'from':deployer})
    dex_record.setDexID(univ3.address, {'from':deployer})
    dex_record.transferOwnership(multisig, {'from': deployer})
    #BZX.setSwapsImplContract(dex_record.address, {'from':multisig})
    addToCalldataSet(calldata_set,BZX.address, BZX.setSwapsImplContract.encode_input(dex_record.address))
    generateGnosisTransactions(calldata_set, gnosisTransactions)
    previewGnosisTransactions(gnosisTransactions)

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
    generateGnosisTransactions(calldata_set, gnosisTransactions)
    previewGnosisTransactions(gnosisTransactions)
    assert False

def migrate(iToken, migrator):
    calldata_set = []
    gnosisTransactions = []
    end = migrator.getLoanCount(iToken)
    count = 5
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(iToken.symbol(),count * x, count)
        calldata_set.append(
            migrator.migrateLoans.encode_input(iToken, count * x, count)
        )
    generateGnosisTransactions(calldata_set, gnosisTransactions)
    previewGnosisTransactions(gnosisTransactions)

def migrateAll():
    supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
    migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)
    for tokenAssetPairA in supportedTokenAssetsPairs:
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
        migrate(existingIToken, migrator)
