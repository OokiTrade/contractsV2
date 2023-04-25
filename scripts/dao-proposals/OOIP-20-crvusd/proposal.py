from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-20-crvusd"

targets = []
values = []
calldatas = []


exec(open("./scripts/env/set-eth.py").read())
MINIMAL_RATES = {
    "icrvUSD":   0.1e18
}

loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x624f7f89414011b276c60ea2337bfba936d1cbbe", abi=LoanTokenLogicStandard.abi)
loanTokenAddress = "TBU"

priceFeedAddress = "TBU"
PRICE_FEED.setPriceFeed([loanTokenAddress], [priceFeedAddress], {"from": TIMELOCK})
PRICE_FEED.setDecimals([loanTokenAddress], {"from": TIMELOCK})

iToken = Contract.from_abi("iToken", "TBU", LoanTokenLogicStandard.abi)

CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol())), iToken, {"from": TIMELOCK})
iToken.setDemandCurve(CUI,{"from": deployer})

BZX.setApprovals([loanTokenAddress], [1,2], {'from': TIMELOCK})
BZX.setupLoanPoolTWAI(iProxy, {"from": TIMELOCK})

BZX.setLoanPool([iToken], [loanTokenAddress], {"from": TIMELOCK})
BZX.setSupportedTokens([loanTokenAddress, iToken], [True, True], True, {"from": TIMELOCK})


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)