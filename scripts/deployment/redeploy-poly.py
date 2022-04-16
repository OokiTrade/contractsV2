exec(open("./scripts/env/set-matic.py").read())
deployer = accounts[2]
from ape_safe import ApeSafe

safe = ApeSafe(GUARDIAN_MULTISIG)
# tickMath = TickMathV1.deploy({"from": deployer})


# loanMaintenance = LoanMaintenance.deploy({"from": deployer})
# loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
# loanOpenings = LoanOpenings.deploy({"from": deployer})
# loanClosings = LoanClosings.deploy({"from": deployer})
# loanSettings = LoanSettings.deploy({"from": deployer})
# swapsImpl = SwapsExternal.deploy({"from": deployer})
tickMath = Contract.from_abi("TickMathV1", "0x425eB009365F03454007e3Ff0D422FDece836a24", TickMathV1.abi)
loanMaintenance = Contract.from_abi("LoanMaintenance", "0x89b45ADec418E79A37975227e9058deE49001048", LoanMaintenance.abi)
loanMaintenance_2 = Contract.from_abi("LoanMaintenance_2", "0x0A04597037a2bfd97C87c08A0EEA7467545f978D", LoanMaintenance_2.abi)
loanOpenings = Contract.from_abi("LoanOpenings", "0x4608D25145374827f14b3b6Ea03B17Bb58432615", LoanOpenings.abi)
loanClosings = Contract.from_abi("LoanClosings", "0x2cA6D57A40E32fB34295861CfdFc7aD822bb9e0c", LoanClosings.abi)
loanSettings = Contract.from_abi("LoanSettings", "0xcde83FC2b4E627338F9c37fdbE84b1FCd17A9fc4", LoanSettings.abi)
swapsImpl = Contract.from_abi("SwapsExternal", "0x19BE8c5869487dD07A635495ED85B4F311C7274B", SwapsExternal.abi)


loanTokenLogicStandard = Contract.from_abi("LoanTokenLogicStandard", "0xB5f8A74310e837a0D0905DF78BDFD4b9cfDb2c99", LoanTokenLogicStandard.abi)
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", "0x640235129F4cE151A501680DEA1e88cAC679a366", LoanTokenLogicWeth.abi)

ookiPriceFeed = Contract.from_abi("OOKIPriceFeed", "0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A", OOKIPriceFeed.abi)
helperImpl = Contract.from_abi("HelperImpl", "0xcBC774c564f84eb6F5A388f97a2F447cC6F26791", HelperImpl.abi)

BZX.replaceContract(loanMaintenance, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanClosings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})

# # remember deploy WETH
# loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
# loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WMATIC:
        print("setting WMATIC")
        iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
    else:
        iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})


# ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer})
pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})

BZX.setTWAISettings(60, 10800, {"from": GUARDIAN_MULTISIG})

for l in list:
    calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})

# helperImpl = HelperImpl.deploy({"from": deployer})

HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# Testing

iUSDC.burn("0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9", 10e6, {"from": "0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9"})
iUSDC.mint("0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9", 1e6, {"from": "0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9"})




















# deployment log
# >>> tickMath = TickMathV1.deploy({"from": deployer})
# Transaction sent: 0xed2369567e042c6572405bd896be378df1854b96584c8cd3ba378444e3597faf
#   Gas price: 127.315172535 gwei   Gas limit: 501806   Nonce: 51
#   TickMathV1.constructor confirmed   Block: 27209992   Gas used: 456188 (90.91%)
#   TickMathV1 deployed at: 0x425eB009365F03454007e3Ff0D422FDece836a24

# >>> loanMaintenance = LoanMaintenance.deploy({"from": deployer})
# Transaction sent: 0x8dbc6c9adac841635ffe6b62e35d3c9c40c34304db15c81cb526ea9ac12453c6
#   Gas price: 117.160489234 gwei   Gas limit: 4735606   Nonce: 52
#   LoanMaintenance.constructor confirmed   Block: 27210010   Gas used: 4305097 (90.91%)
#   LoanMaintenance deployed at: 0x89b45ADec418E79A37975227e9058deE49001048

# >>> loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
# Transaction sent: 0x9ba2d497fdc2156df707ef5eb83453e41fb1278e4aa6961d3effb54b834d54bf
#   Gas price: 107.224025247 gwei   Gas limit: 3195032   Nonce: 53
#   LoanMaintenance_2.constructor confirmed   Block: 27210036   Gas used: 2904575 (90.91%)
#   LoanMaintenance_2 deployed at: 0x0A04597037a2bfd97C87c08A0EEA7467545f978D

# >>> loanOpenings = LoanOpenings.deploy({"from": deployer})
# Transaction sent: 0x4b77213e9b802fd657a6908a02df33c53b7f2faf7c509d6f87141688d55f8a8c
#   Gas price: 113.748818711 gwei   Gas limit: 5131964   Nonce: 54
#   LoanOpenings.constructor confirmed   Block: 27210061   Gas used: 4665422 (90.91%)
#   LoanOpenings deployed at: 0x4608D25145374827f14b3b6Ea03B17Bb58432615

# >>> loanClosings = LoanClosings.deploy({"from": deployer})
# Transaction sent: 0xc275ff2c9c78e06ecace7b28563c53ff97e9b892fc0589d5c4519b540ac60ead
#   Gas price: 94.676851812 gwei   Gas limit: 6012055   Nonce: 55
#   LoanClosings.constructor confirmed   Block: 27210102   Gas used: 5465505 (90.91%)
#   LoanClosings deployed at: 0x2cA6D57A40E32fB34295861CfdFc7aD822bb9e0c

# >>> loanSettings = LoanSettings.deploy({"from": deployer})
# Transaction sent: 0x166125ffb831d6dae9b3f45228c28b03004f32bffc69763ce4ee83b7a52f54ec
#   Gas price: 86.438377761 gwei   Gas limit: 3718850   Nonce: 56
#   LoanSettings.constructor confirmed   Block: 27210131   Gas used: 3380773 (90.91%)
#   LoanSettings deployed at: 0xcde83FC2b4E627338F9c37fdbE84b1FCd17A9fc4

# >>> swapsImpl = SwapsExternal.deploy({"from": deployer})
# Transaction sent: 0x519ae140ace46c0e5984901953a6433550fefccb2757736a7241097b0207b901
#   Gas price: 93.228166979 gwei   Gas limit: 3598356   Nonce: 57
#   SwapsExternal.constructor confirmed   Block: 27210153   Gas used: 3271233 (90.91%)
#   SwapsExternal deployed at: 0x19BE8c5869487dD07A635495ED85B4F311C7274B

# >>> loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
# Transaction sent: 0x9bcfc288b5940999f7284f074d62ceecca9e9e4c218a6cd80f6296e4da9eff1d
#   Gas price: 94.076073769 gwei   Gas limit: 4682540   Nonce: 58
#   LoanTokenLogicStandard.constructor confirmed   Block: 27210167   Gas used: 4236955 (90.48%)
#   LoanTokenLogicStandard deployed at: 0xB5f8A74310e837a0D0905DF78BDFD4b9cfDb2c99

# >>> loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})
# Transaction sent: 0xf572101fcde98c7e560ad1bae582c6f9c82d67971692c5b8d6fb99d4b0a0f151
#   Gas price: 99.089336851 gwei   Gas limit: 4852588   Nonce: 59
#   LoanTokenLogicWeth.constructor confirmed   Block: 27210177   Gas used: 4391544 (90.50%)
#   LoanTokenLogicWeth deployed at: 0x640235129F4cE151A501680DEA1e88cAC679a366

# >>> ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer})
# Transaction sent: 0x884f2f6a88c1e6430c741a1f7175c54954fbbf6f84da52e1161d99092c47df8a
#   Gas price: 98.32311762 gwei   Gas limit: 734708   Nonce: 60
#   OOKIPriceFeed.constructor confirmed   Block: 27210189   Gas used: 667917 (90.91%)
#   OOKIPriceFeed deployed at: 0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A

# >>> helperImpl = HelperImpl.deploy({"from": deployer})
# Transaction sent: 0x1f718fa79ead6a3951e9cce39ac30613b7b252a5d6edea19d93c22e8809d047d
#   Gas price: 86.162005098 gwei   Gas limit: 1781591   Nonce: 61
#   HelperImpl.constructor confirmed   Block: 27210208   Gas used: 1619629 (90.91%)
#   HelperImpl deployed at: 0xcBC774c564f84eb6F5A388f97a2F447cC6F26791

# >>> TickMathV1.publish_source(tickMath)
# Verification submitted successfully. Waiting for result...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanMaintenance.publish_source(loanMaintenance)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanMaintenance_2.publish_source(loanMaintenance_2)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanOpenings.publish_source(loanOpenings)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanClosings.publish_source(loanClosings)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanSettings.publish_source(loanSettings)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> SwapsExternal.publish_source(swapsImpl)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanTokenLogicStandard.publish_source(loanTokenLogicStandard)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> LoanTokenLogicWeth.publish_source(loanTokenLogicWeth)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> OOKIPriceFeed.publish_source(ookiPriceFeed)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> HelperImpl.publish_source(helperImpl)
# Verification submitted successfully. Waiting for result...
# Verification pending...
# Verification pending...
# Verification complete. Result: Pass - Verified
# True
# >>> ookiPriceFeed.updateStoredPrice(15e5, {"from": deployer})
# Transaction sent: 0xd095b478f20420bc202c32d1e8768f5c4eb3541f1e926b5464428a1dacca09f5
#   Gas price: 34.583173968 gwei   Gas limit: 33939   Nonce: 62
#   OOKIPriceFeed.updateStoredPrice confirmed   Block: 27210598   Gas used: 30854 (90.91%)

# <Transaction '0xd095b478f20420bc202c32d1e8768f5c4eb3541f1e926b5464428a1dacca09f5'>
# >>> ookiPriceFeed.transferOwnership(GUARDIAN_MULTISIG, {"from": deployer})
# Transaction sent: 0x95501e3c958523b5165f72b63b54632c808fabe93382d7a9a03a18c4c77a36fb
#   Gas price: 33.158256636 gwei   Gas limit: 31579   Nonce: 63
#   OOKIPriceFeed.transferOwnership confirmed   Block: 27210646   Gas used: 28709 (90.91%)

# <Transaction '0x95501e3c958523b5165f72b63b54632c808fabe93382d7a9a03a18c4c77a36fb'>