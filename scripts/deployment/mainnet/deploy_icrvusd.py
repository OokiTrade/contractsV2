
exec(open("./scripts/env/set-eth.py").read())
MINIMAL_RATES = {
    "icrvUSD":   0.1e18
}

loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x624f7f89414011b276c60ea2337bfba936d1cbbe", abi=LoanTokenLogicStandard.abi)
loanTokenAddress = TestToken.deploy("crvusd", "crvusd", 18, 1000e18,{"from": deployer}).address

priceFeedAddress = FixedPriceFeed.deploy({"from": deployer}).address
PRICE_FEED.setPriceFeed([loanTokenAddress], [priceFeedAddress], {"from": TIMELOCK})
PRICE_FEED.setDecimals([loanTokenAddress], {"from": TIMELOCK})

iProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
#iProxy = Contract.from_abi("iToken", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanToken.abi)
iToken = Contract.from_abi("iToken", iProxy, LoanTokenLogicStandard.abi)
underlyingSymbol = "crvUSD"
iTokenSymbol = "i{}".format(underlyingSymbol)
iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
iToken.initialize(loanTokenAddress, iTokenName, iTokenSymbol, {'from': deployer})
iToken.initializeDomainSeparator({"from": deployer})
iProxy.transferOwnership(TIMELOCK, {'from': deployer})

CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol())), iToken, {"from": TIMELOCK})
iToken.setDemandCurve(CUI,{"from": deployer})

BZX.setApprovals([loanTokenAddress], [1,2], {'from': TIMELOCK})
BZX.setupLoanPoolTWAI(iProxy, {"from": TIMELOCK})

BZX.setLoanPool([iToken], [loanTokenAddress], {"from": TIMELOCK})
BZX.setSupportedTokens([loanTokenAddress, iToken], [True, True], True, {"from": TIMELOCK})


exec(open("./scripts/env/set-eth.py").read())
crvUSD = TestToken.at(loanTokenAddress)