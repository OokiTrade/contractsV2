acct = accounts[0]
BZX = Contract.from_abi("bzx", address="0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B", abi=interface.IBZx.abi, owner=acct)
MATIC = Contract.from_abi("MATIC", address="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", abi=TestToken.abi, owner=acct)
ETH = Contract.from_abi("ETH", address="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", abi=TestToken.abi, owner=acct)
WBTC = Contract.from_abi("WBTC", address="0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", abi=TestToken.abi, owner=acct)
LINK = Contract.from_abi("LINK", address="0xb0897686c545045afc77cf20ec7a532e3120e0f1", abi=TestToken.abi, owner=acct)
USDC = Contract.from_abi("USDC", address="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", abi=TestToken.abi, owner=acct)
USDT = Contract.from_abi("USDT", address="0xc2132D05D31c914a87C6611C10748AEb04B58e8F", abi=TestToken.abi, owner=acct)
AAVE = Contract.from_abi("AAVE", address="0xD6DF932A45C0f255f85145f286eA0b292B21C90B", abi=TestToken.abi, owner=acct)
BZRX = Contract.from_abi("BZRX", address="0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9", abi=TestToken.abi, owner=acct)


iMATIC = Contract.from_abi("iMATIC", address=MATIC.address, abi=LoanTokenLogicWeth.abi, owner=acct)
iETH = Contract.from_abi("iETH", address=ETH.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iWBTC = Contract.from_abi("iWBTC", address=WBTC.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iLINK = Contract.from_abi("iLINK", address=LINK.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iUSDC = Contract.from_abi("iUSDC", address=USDC.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iUSDT = Contract.from_abi("iUSDT", address=USDT.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iAAVE = Contract.from_abi("iAAVE", address=AAVE.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iBZRX = Contract.from_abi("iBZRX", address=AAVE.address, abi=LoanTokenLogicStandard.abi, owner=acct)


usdcacc = "0x1a13F4Ca1d028320A707D99520AbFefca3998b7F"
USDC.transfer(acct, USDC.balanceOf(usdcacc), {'from': usdcacc})

wmaticacc = "0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4"
MATIC.transfer(acct, MATIC.balanceOf(wmaticacc), {'from': wmaticacc})


linkacc = "0x74D23F21F780CA26B47Db16B0504F2e3832b9321"
LINK.transfer(acct, LINK.balanceOf(linkacc), {'from': linkacc})

ethacc = "0x28424507fefb6f7f8E9D3860F56504E4e5f5f390"
ETH.transfer(acct, ETH.balanceOf(ethacc), {'from': ethacc})


print ("Mint iusdt")
amount = USDC.balanceOf(acct)/2
USDC.approve(iUSDC, 2**256-1, {'from': acct})
iUSDC.mint(acct, amount, {'from': acct})
iUSDC.approve(acct, 2**256-1, {'from': acct})

print ("Mint imatic")
amount = MATIC.balanceOf(acct)/2
MATIC.approve(iMATIC, 2**256-1, {'from': acct})
iMATIC.mint(acct, amount, {'from': acct})
iMATIC.approve(acct, 2**256-1, {'from': acct})

