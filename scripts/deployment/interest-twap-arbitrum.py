# 1 deploy contracts
# 2 upgrade cui
# 3 upgrade protocol
    # LoanClosingsBase_Arbitrum - abstract
    # LoanMaintenance_Arbitrum
    # LoanMaintenance
    # LoanMaintenance_2
    # LoanMigration - this we don't need
    # LoanOpenings - deploy
    # LoanSettings - deploy
# 4 init setupLoanPoolTWAI
exec(open("./scripts/env/set-arbitrum.py").read())
# <CurvedInterestRate Contract '0x1De60479e3310f2d92CD87ef111c7A795e7C0A82'>
cui = CurvedInterestRate.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})  
# <TickMath Contract '0x37A3fC76105c51D54a9c1c3167e30601EdeE8782'>
tickMath = TickMath.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})

# <LoanMaintenance_Arbitrum Contract '0x2F3A1964E1e5959B4f006bE062479B24fC806BB0'>
loanMaintenance_Arbitrum = LoanMaintenance_Arbitrum.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# <LoanMaintenance Contract '0xAaD3b6e314b3b31BE6d42A5D8eFfAe4cDB6d2d4F'>
loanMaintenance = LoanMaintenance.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# <LoanMaintenance_2 Contract '0x7fC67DAA325BEC82e829685290aeec990f412AB2'>
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# <LoanOpenings Contract '0xD36913f0225E64C4689b5D6144CeF952d1ad23dA'>
loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# <LoanSettings Contract '0x49743dA77Ff019424E2e153A0712eD87fFDB74Eb'>
loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})


calldata1 = LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(cui)
calldata2 = iUSDC.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, calldata1)
# for l in list:
#     iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
#     iTokenTemp.updateSettings(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, calldata, {"from": GUARDIAN_MULTISIG})
data = []
for l in list:
    data.append([l[0], calldata2])

data1 = MULTICALL3.tryAggregate.encode_input(True, data) 
safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, 1)

BZX.replaceContract(loanMaintenance_Arbitrum, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})


