exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[2]
from gnosis.safe import Safe, SafeOperation
from ape_safe import ApeSafe

safe = ApeSafe(GUARDIAN_MULTISIG)

tickMath = TickMathV1.deploy({"from": deployer})
loanMaintenance = LoanMaintenance.deploy({"from": deployer})
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
loanOpenings = LoanOpenings.deploy({"from": deployer})
loanClosings = LoanClosings.deploy({"from": deployer})
loanSettings = LoanSettings.deploy({"from": deployer})
swapsImpl = SwapsExternal.deploy({"from": deployer})

BZX.replaceContract(loanMaintenance, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanClosings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})

# # remember deploy WETH
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WBNB:
        print("setting WBNB")
        iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
    else:
        iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})


# # ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer})
# pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
# pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})

BZX.setTWAISettings(60, 10800, {"from": GUARDIAN_MULTISIG})

for l in list:
    calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})


# data1 = MULTICALL3.tryAggregate.encode_input(True, arr)
# safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, SafeOperation.DELEGATE_CALL.value, safe_nonce=safe.pending_nonce())

# helperImpl = HelperImpl.deploy({"from": deployer})
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# Testing

iUSDC.burn("X", 10e6, {"from": "X"})
iUSDC.mint("X", 1e6, {"from": "X"})

