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
loanTokenAddress = "0xf71040d20Cc3FFBb28c1abcEF46134C7936624e0"
priceFeedAddress = "0x986b5E1e1755e3C2440e960477f25201B0a8bbD4" #Chainlink USDC pricefeed

calldatas.append(PRICE_FEED.setPriceFeed.encode_input([loanTokenAddress], [priceFeedAddress]))
targets.append(PRICE_FEED.address)

calldatas.append(PRICE_FEED.setDecimals.encode_input([loanTokenAddress]))
targets.append(PRICE_FEED.address)
deployer = accounts[0]
iProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
iToken = Contract.from_abi("iToken", iProxy, LoanTokenLogicStandard.abi)
underlyingSymbol = "crvUSD"
iTokenSymbol = "i{}".format(underlyingSymbol)
iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
iToken.initialize(loanTokenAddress, iTokenName, iTokenSymbol, {'from': deployer})
iToken.initializeDomainSeparator({"from": deployer})
iToken.setDemandCurve(CUI,{"from": deployer})

iProxy.transferOwnership(TIMELOCK, {'from': deployer})

calldatas.append(iToken.setDemandCurve.encode_input(CUI))
targets.append(iToken.address)

calldatas.append(BZX.setApprovals.encode_input([loanTokenAddress], [1,2]))
targets.append(BZX.address)

calldatas.append(BZX.setupLoanPoolTWAI.encode_input(iToken))
targets.append(BZX.address)

calldatas.append(BZX.setLoanPool.encode_input([iToken], [loanTokenAddress]))
targets.append(BZX.address)

calldatas.append(BZX.setSupportedTokens.encode_input([loanTokenAddress, iToken], [True, True], True))
targets.append(BZX.address)

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)