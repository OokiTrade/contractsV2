
exec(open("./scripts/env/set-arbitrum.py").read())
# MINIMAL_RATES = {
#     "iARB":   0.1e18
# }
# loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0x9DF59cc228C19b4D63888dFD910d1Fd9A6a4d8C9", abi=LoanTokenLogicStandard.abi)
loanTokenAddress = '0x912CE59144191C1204E64559FE8253a0e49E6548'
#
# # priceFeedAddress = 'TBU' #Chainlink
# # PRICE_FEED.setPriceFeed([loanTokenAddress], [priceFeedAddress], {"from": GUARDIAN_MULTISIG})
# # PRICE_FEED.setDecimals([loanTokenAddress], {"from": GUARDIAN_MULTISIG})
#
# #iProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
iProxy = Contract.from_abi("iToken", address="0x08bd8Dc0721eF4898537a5FBE1981333D430F50f", abi=LoanToken.abi)
iToken = Contract.from_abi("iToken", iProxy, LoanTokenLogicStandard.abi)
# # underlyingSymbol = "ARB"
# # iTokenSymbol = "i{}".format(underlyingSymbol)
# # iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
# # iToken.initialize(loanTokenAddress, iTokenName, iTokenSymbol, {'from': deployer})
# # iToken.initializeDomainSeparator({"from": deployer})
#
# CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol())), iToken, {"from": GUARDIAN_MULTISIG})
# # iToken.setDemandCurve(CUI,{"from": deployer})
#
# BZX.setApprovals([loanTokenAddress], [1,2], {'from': GUARDIAN_MULTISIG})
# BZX.setupLoanPoolTWAI(iProxy, {"from": GUARDIAN_MULTISIG})
#
# BZX.setLoanPool([iToken], [loanTokenAddress], {"from": GUARDIAN_MULTISIG})
BZX.setSupportedTokens([loanTokenAddress, iToken], [True, True], True, {"from": GUARDIAN_MULTISIG})

# iProxy.transferOwnership(GUARDIAN_MULTISIG, {'from': deployer})

exec(open("./scripts/env/set-arbitrum.py").read())
ARB = TestToken.at(loanTokenAddress)