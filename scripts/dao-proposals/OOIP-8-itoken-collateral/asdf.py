exec(open("./scripts/env/set-eth.py").read())

base_data = [
    b"0x0",  # id
    False,  # active
    str(TIMELOCK),  # owner
    "0x0000000000000000000000000000000000000001",  # loanToken
    "0x0000000000000000000000000000000000000002",  # collateralToken
    Wei("20 ether"),  # minInitialMargin
    Wei("15 ether"),  # maintenanceMargin
    0  # fixedLoanTerm
]

base_data_copy[3] = underlying
base_data_copy[4] = iToken_collateral # pair is iToken, Underlying
print(base_data_copy)