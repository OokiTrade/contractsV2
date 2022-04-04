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
# exec(open("./scripts/env/set-arbitrum.py").read())
exec(open("./scripts/env/set-bsc.py").read())
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
deployer = accounts[2]
# <CurvedInterestRate Contract '0x1De60479e3310f2d92CD87ef111c7A795e7C0A82'> Arbitrum
# <CurvedInterestRate Contract '0xaad3b6e314b3b31be6d42a5d8effae4cdb6d2d4f'> BSC
# cui = CurvedInterestRate.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})  
# # <TickMath Contract '0x37A3fC76105c51D54a9c1c3167e30601EdeE8782'>
# tickMath = TickMath.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# t = TickMath.at("0x37A3fC76105c51D54a9c1c3167e30601EdeE8782")

# INVALID <LoanMaintenance_Arbitrum Contract '0x2F3A1964E1e5959B4f006bE062479B24fC806BB0'> Arbitrum
# <LoanMaintenance_Arbitrum Contract '0x0DAE2558B8438c5089112F730aa319a2727E9912'> Arbitrum
loanMaintenance_Arbitrum = LoanMaintenance_Arbitrum.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

# INVALID <LoanMaintenance_2 Contract '0x7fC67DAA325BEC82e829685290aeec990f412AB2'> Arbitrum
# <LoanMaintenance_2 Contract '0x1CFE42F0a4ff79CCbC131E6EBDFab01D376D00c3'> Arbitrum
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
# INVALID <LoanOpenings Contract '0xD36913f0225E64C4689b5D6144CeF952d1ad23dA'> Arbitrum
# <LoanOpenings Contract '0x831dFCa1fB4C35bB68F4B5D94Ce81a2072E2dFEe'> Arbitrum
loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})
# <LoanClosings_Arbitrum Contract '0xf7Eb8B08C8860d494D8d8FB6529C46Df599987BB'> Arbitrum
loanClosings_Arbitrum = LoanClosings_Arbitrum.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})

# INVALID <LoanSettings Contract '0x49743dA77Ff019424E2e153A0712eD87fFDB74Eb'> Arbitrum
# <LoanSettings Contract '0xE42f4147Ce8bf8D436554feE950ef11DBCeB90f7'> Arbitrum
loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.6 gwei")})


calldata1 = LOAN_TOKEN_SETTINGS_LOWER_ADMIN.setDemandCurve.encode_input(cui)
calldata2 = iUSDT.updateSettings.encode_input(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, calldata1)
# for l in list:
#     iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanTokenLogicStandard.abi)
#     iTokenTemp.updateSettings(LOAN_TOKEN_SETTINGS_LOWER_ADMIN, calldata1, {"from": GUARDIAN_MULTISIG})
data = []
for l in list:
    data.append([l[0], calldata2])

# data1 = MULTICALL3.tryAggregate.encode_input(True, data) 
# safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, 1)

# BZX.replaceContract(loanMaintenance_Arbitrum, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanClosings_Arbitrum, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
arr = []
calldata = BZX.replaceContract.encode_input(loanMaintenance_Arbitrum)
arr.append([BZX, calldata])
calldata = BZX.replaceContract.encode_input(loanMaintenance_2)
arr.append([BZX, calldata])
calldata = BZX.replaceContract.encode_input(loanOpenings)
arr.append([BZX, calldata])
calldata = BZX.replaceContract.encode_input(loanClosings_Arbitrum)
arr.append([BZX, calldata])
calldata = BZX.replaceContract.encode_input(loanSettings)
arr.append([BZX, calldata])

for l in list:
    calldata = BZX.setupLoanPoolTWAI.encode_input(l[0])
    arr.append([BZX, calldata])

data1 = MULTICALL3.tryAggregate.encode_input(True, arr) 
safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, 1)


# testing
USDT.transfer(accounts[0], 1000e6, {'from': "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641"})
USDT.approve(iUSDT, 1000e6, {"from":  accounts[0]})
iUSDT.mint(accounts[0], 150e6, {'from': accounts[0]})
