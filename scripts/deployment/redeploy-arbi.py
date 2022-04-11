exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts[2]
tickMath = TickMath.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})


loanMaintenance_Arbitrum = LoanMaintenance_Arbitrum.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanClosings_Arbitrum = LoanClosings_Arbitrum.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
swapsImpl = SwapsExternal.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})


BZX.replaceContract(loanMaintenance_Arbitrum, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanClosings_Arbitrum, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})

# remember deploy WETH
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
LoanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[0] == WETH:
        iTokenTemp.setTarget(LoanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
    else:
        iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})


ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})


for l in list:
    calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})

# Testing
iUSDC.mint("X", 1e6, {"from": "X"})