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
calldatas.append(PRICE_FEED.setPriceFeed.encode_input([loanTokenAddress], [priceFeedAddress]))
calldatas.append(PRICE_FEED.setDecimals.encode_input([loanTokenAddress]))

iToken = Contract.from_abi("iToken", "TBU", LoanTokenLogicStandard.abi)

calldatas.append(CUI.updateParams.encode_input((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol()))))
calldatas.append(iToken.setDemandCurve.encode_input(CUI))

calldatas.append(BZX.setApprovals.encode_input([loanTokenAddress], [1,2]))
calldatas.append(BZX.setupLoanPoolTWAI.encode_input(iProxy))

calldatas.append(BZX.setLoanPool.encode_input([iToken], [loanTokenAddress]))
calldatas.append(BZX.setSupportedTokens.encode_input([loanTokenAddress, iToken], [True, True], True))


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)