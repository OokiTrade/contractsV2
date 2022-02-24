exec(open("./scripts/env/set-matic.py").read())

deployer = accounts[0]
multisign = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"

calldata_set = []
def addToCalldataSet(target, calldata):
    calldata_set.append(
        {
            'target': target,
            'calldata': calldata
        }
    )

def replaceIToken(itoken, token, loanTokenLogicStandard):
    iTokenProxy = Contract.from_abi("iUSDCProxy", address=itoken.address, abi=LoanToken.abi)
    iTokenProxy.setTarget(loanTokenLogicStandard, {'from': multisign})
    #addToCalldataSet(iTokenProxy.address, iTokenProxy.setTarget.encode_input(loanTokenLogicStandard))
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    calldata = LOAN_TOKEN_SETTINGS.initialize.encode_input(token, iToken.name(), iToken.symbol())
    iToken.updateSettings(LOAN_TOKEN_SETTINGS, calldata, {"from": multisign})
    #addToCalldataSet(iToken.address, iToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS.address, calldata))

    return iToken

def updateMarginSettings(LOAN_TOKEN_SETTINGS, iToken, CUI):
    calldata = LOAN_TOKEN_SETTINGS.setDemandCurve.encode_input(CUI)
    iToken.updateSettings(LOAN_TOKEN_SETTINGS, calldata,{"from": multisign})
    #addToCalldataSet(iToken.address, iToken.updateSettings.encode_input(LOAN_TOKEN_SETTINGS.address, calldata))

def updateBZXModule(BZX, module):
    moduleImpl = module.deploy({'from': deployer})
    BZX.replaceContract(moduleImpl.address, {'from': multisign})
    #addToCalldataSet(BZX.address, BZX.replaceContract.encode_input(moduleImpl.address))

# Deploy LoanTokenSettings
LOAN_TOKEN_SETTINGS = deployer.deploy(LoanTokenSettings)
LOAN_TOKEN_SETTINGS.transferOwnership(multisign, {'from': deployer})
loanTokenLogicStandard = LoanTokenLogicStandard.deploy(multisign, {'from': deployer}).address

# Deploy CurvedInterestRate
CUI = CurvedInterestRate.deploy({'from':deployer})

print("Update BZX modules")
## LoanSettings
updateBZXModule(BZX, LoanSettings)
## LoanOpenings
updateBZXModule(BZX, LoanOpenings)
## LoanMaintenance
updateBZXModule(BZX, LoanMaintenance_2)
## LoanMigration
updateBZXModule(BZX, LoanMigration)
## LoanMaintenance
updateBZXModule(BZX, LoanMaintenance)
## LoanClosings
updateBZXModule(BZX, LoanClosings)
## SwapsExternal
updateBZXModule(BZX, SwapsExternal)
## ProtocolSettings
updateBZXModule(BZX, ProtocolSettings)

print("Deploying Dex Selector and Implementations")
dex_record = DexRecords.deploy({'from':deployer})
univ2 = SwapsImplUniswapV2_POLYGON.deploy({'from':deployer})
univ3 = SwapsImplUniswapV3_ETH.deploy({'from':deployer})
dex_record.setDexID(univ2.address, {'from':deployer})
dex_record.setDexID(univ3.address, {'from':deployer})
dex_record.transferOwnership(multisign, {'from': deployer})
BZX.setSwapsImplContract(dex_record.address, {'from':multisign})
#addToCalldataSet(BZX.address, BZX.setSwapsImplContract.encode_input(dex_record.address))

supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)
migrator = Contract.from_abi("migrator", BZX, abi=LoanMigration.abi)

for tokenAssetPairA in supportedTokenAssetsPairs:
    existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi)
    existingToken = Contract.from_abi("token", address=tokenAssetPairA[1], abi=interface.IERC20.abi)
    print("Deploying iToken impl", existingIToken)
    replaceIToken(existingIToken, existingToken, loanTokenLogicStandard)
    print("Update curve", existingIToken)
    updateMarginSettings(LOAN_TOKEN_SETTINGS, existingIToken, CUI)
    end = migrator.getLoanCount(existingIToken)
    count = 5
    n = int(end/count)
    if(end % count > 0):
        n = n + 1
    print("end", end)
    print("count", count)
    print("n", n)
    for x in range(0, n):
        print(existingIToken.symbol(),count * x, count)
        migrator.migrateLoans(existingIToken, count * x, count, {'from': multisign})
