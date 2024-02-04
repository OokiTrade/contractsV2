exec(open("./scripts/env/set-goerly-base.py").read())
MINIMAL_RATES = {
    "iUSDO":   0.1e18,
    "iBTCO": 0.1e18
}
ousd = Contract.from_abi("TestToken", address="0xF45E2FA255d8290502e0CdF63d0E1D6FaA09B561", abi=TestToken.abi)
obtc = Contract.from_abi("TestToken", address="0xb2cC25fd0Cf139044417de18DF8305c8dAA11888", abi=TestToken.abi)

loanTokenAddresses = [
    ousd.address,
    obtc.address
]

pricefeeds = {
    ousd.address: "0xb85765935B4d9Ab6f841c9a00690Da5F34368bc0",
    obtc.address:"0xAC15714c08986DACC0379193e22382736796496f"
}

itokens = {
    ousd.address: "0xE3bf7FA6249D5caC1B2E5AE12B491B94838dE897",
    obtc.address:"0x328034d93d13ff4c453eAEC1368069A7578C18B3"
}

loanTokenLogicStandard = Contract.from_abi("loanTokenLogicStandard", address="0xe5495dE5b0Fdef7326EC5F89972e8c80Be11F6fa", abi=LoanTokenLogicStandard.abi)

for loanTokenAddress in loanTokenAddresses:
    token = Contract.from_abi("testtoken", address=loanTokenAddress, abi=TestToken.abi)
    priceFeedAddress = pricefeeds[loanTokenAddress]
    PRICE_FEED.setPriceFeed([loanTokenAddress], [priceFeedAddress], {"from": deployer})
    PRICE_FEED.setDecimals([loanTokenAddress], {"from": deployer})

    #iProxy = LoanToken.deploy(deployer, loanTokenLogicStandard, {"from": deployer})
    iProxy = Contract.from_abi("iToken", address=itokens[loanTokenAddress], abi=LoanToken.abi)
    iToken = Contract.from_abi("iToken", iProxy, LoanTokenLogicStandard.abi)

    underlyingSymbol = token.symbol()
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
    iToken.initialize(loanTokenAddress, iTokenName, iTokenSymbol, {'from': deployer})
    iToken.initializeDomainSeparator({"from": deployer})

    CUI.updateParams((120e18, 80e18, 100e18, 100e18, 110e18, MINIMAL_RATES.get(iToken.symbol()), MINIMAL_RATES.get(iToken.symbol())), iToken, {"from": deployer})
    iToken.setDemandCurve(CUI,{"from": deployer})

    BZX.setApprovals([loanTokenAddress], [1], {'from': deployer})
    BZX.setupLoanPoolTWAI(iProxy, {"from": deployer})

    BZX.setLoanPool([iToken], [loanTokenAddress], {"from": deployer})

    BZX.setSupportedTokens([loanTokenAddress, iToken], [True, True], True, {"from": deployer})

exec(open("./scripts/env/set-goerly-base.py").read())
swapImpl = SwapsImplUniswapV2_GOERLYBASE.deploy({'from': deployer})
dex = DexRecords.deploy({'from':deployer})
dex.setDexID(swapImpl, {'from':deployer})
BZX.setSwapsImplContract(dex, {'from': deployer})
BZX.setSupportedTokens([WETH, TUSD], [False, False], False, {'from': deployer})


BTCO.mint(deployer, 10000e8, {'from': deployer})
USDO.mint(deployer, 1000000e6, {'from': deployer})

USDO.approve(iUSDO, 2**256-1, {'from': deployer})
BTCO.approve(iBTCO, 2**256-1, {'from': deployer})
USDO.approve(iBTCO, 2**256-1, {'from': deployer})
BTCO.approve(iUSDO, 2**256-1, {'from': deployer})

iBTCO.mint(deployer, 10e8, {'from': deployer})
iUSDO.mint(deployer, 10000e6, {'from': deployer})


