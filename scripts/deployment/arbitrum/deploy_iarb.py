
exec(open("./scripts/env/set-arbitrum.py").read())
MINIMAL_RATES = {
    "iARB":   0.1e18
}
loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9", abi=LoanTokenLogicStandard.abi)
loanTokenAddress = 'TBU'

priceFeedAddress = 'TBU' #Chainlink
PRICE_FEED.setPriceFeed([loanTokenAddress], [priceFeedAddress], {"from": GUARDIAN_MULTISIG})
PRICE_FEED.setDecimals([loanTokenAddress], {"from": GUARDIAN_MULTISIG})

iProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
#iToken = Contract.from_abi("iToken", address="", abi=LoanToken.abi)
iToken = Contract.from_abi("iToken", iProxy, LoanTokenLogicStandard.abi)
underlyingSymbol = "ARB"
iTokenSymbol = "i{}".format(underlyingSymbol)
iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
iToken.initialize(loanTokenAddress, iTokenName, iTokenSymbol, {'from': deployer})
iToken.initializeDomainSeparator({"from": deployer})

CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol())), iToken, {"from": GUARDIAN_MULTISIG})
iToken.setDemandCurve(CUI,{"from": deployer})

BZX.setApprovals([loanTokenAddress], [1,2], {'from': GUARDIAN_MULTISIG})
BZX.setupLoanPoolTWAI(iProxy, {"from": GUARDIAN_MULTISIG})

BZX.setLoanPool([iToken], [loanTokenAddress], {"from": GUARDIAN_MULTISIG})
BZX.setSupportedTokens([loanTokenAddress, iToken], [True, True], True, {"from": GUARDIAN_MULTISIG})
iProxy.transferOwnership(GUARDIAN_MULTISIG, {'from': deployer})

exec(open("./scripts/env/set-arbitrum.py").read())

assert False
##Test!!!!!!
ARB = TestToken.at(loanTokenAddress)
acc = "TBU"
ARB.transfer(accounts[0], 1000e18, {'from': acc})
ARB.approve(iETH, 2**256-1, {'from': accounts[0]})
ARB.approve(iARB, 2**256-1, {'from': accounts[0]})
iARB.approve(iETH, 2**256-1, {'from': accounts[0]})
iARB.mint(accounts[0], 100e18, {'from': accounts[0]})

iARB.borrow(0x0000000000000000000000000000000000000000000000000000000000000000, 1000000, 7884000, 0.01e18, ZERO_ADDRESS, accounts[0], accounts[0], b'', {'from': accounts[0], 'value':0.01e18})
iETH.borrow(0x0000000000000000000000000000000000000000000000000000000000000000, 1000000, 7884000, 5e18, ARB, accounts[0], accounts[0], b'', {'from': accounts[0]})
iETH.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 5e18, ARB, accounts[0], b'', {'from': accounts[0]})
iARB.marginTrade(0x0000000000000000000000000000000000000000000000000000000000000000, 2000000000000000000, 0, 0.01e18, ZERO_ADDRESS, accounts[0], b'', {'from': accounts[0], 'value':0.01e18})

assert False