exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts[2]
tickMath = TickMathV1.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})


loanMaintenance_Arbitrum = LoanMaintenance.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanClosings_Arbitrum = LoanClosings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
swapsImpl = SwapsExternal.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
receiver = Receiver.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})


BZX.replaceContract(loanMaintenance_Arbitrum, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanClosings_Arbitrum, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(receiver, {"from": GUARDIAN_MULTISIG})

# remember deploy WETH
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WETH:
        print("setting weth")
        iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
    else:
        iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})


ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})


for l in list:
    calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})


helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)
# Testing
iUSDC.mint("X", 1e6, {"from": "X"})