import time
from web3.gas_strategies.time_based import fast_gas_price_strategy
#exec(open("./scripts/env/set-matic.py").read())
account = accounts.load("ffff")
pgovbot = accounts.load("pgovbot")
gasPrice = Wei('5 gwei')
web3.eth.setGasPriceStrategy(fast_gas_price_strategy)
while(True):
    try:
        MATIC = Contract.from_abi("MATIC", address="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", abi=interface.ERC20.abi)
        CRV = Contract.from_abi("CRV", address="0x172370d5cd63279efa6d502dab29171933a610af", abi=interface.ERC20.abi)
        ETH = Contract.from_abi("ETH", address="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", abi=interface.ERC20.abi)
        USDC = Contract.from_abi("USDC", address="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", abi=interface.ERC20.abi)
        USDT = Contract.from_abi("USDT", address="0xc2132D05D31c914a87C6611C10748AEb04B58e8F", abi=interface.ERC20.abi)
        PGOV = Contract.from_abi("PGOV", address="0xd5d84e75f48E75f01fb2EB6dFD8eA148eE3d0FEb", abi=interface.ERC20.abi)

        maticBalance = MATIC.balanceOf(account)
        crvBalance = CRV.balanceOf(account)

        if(maticBalance>100):
            quote = SUSHI_ROUTER.getAmountsOut(maticBalance, [MATIC, ETH, CRV])
            ratio = quote[0]/quote[2]
            if(ratio <= 1.255):
                SUSHI_ROUTER.swapExactTokensForTokens(maticBalance, [MATIC, ETH, CRV], account, chain.time() + 60, {"from": account})
        if(crvBalance>100):
            quote = SUSHI_ROUTER.getAmountsOut(crvBalance, [CRV, ETH, MATIC])
            ratio = quote[2]/quote[1]
            if(ratio >= 1.31):
                SUSHI_ROUTER.swapExactTokensForTokens(maticBalance, [CRV, ETH, MATIC], account, chain.time() + 60, {"from": account})

        message = f"[MATIC/CRV]: maticBalance: {maticBalance/1e18}, crvBalance: {crvBalance/1e18}, ratio: {ratio}. Working...";
        print(message)
        #######

        pgovBalance = PGOV.balanceOf(pgovbot)
        maticBalance = MATIC.balanceOf(pgovbot)
        if(maticBalance>100):
            quote = SUSHI_ROUTER.getAmountsOut(maticBalance, [MATIC, PGOV])
            ratio = quote[0]/quote[1]
            if(ratio <= 0.02):
                SUSHI_ROUTER.swapExactTokensForTokens(maticBalance, [MATIC, PGOV], account, chain.time() + 60, {"from": account})

        if(pgovBalance>100):
            quote = SUSHI_ROUTER.getAmountsOut(pgovBalance, [PGOV, MATIC])
            ratio = quote[1]/quote[0]
            if(ratio >= 0.021):
                SUSHI_ROUTER.swapExactTokensForTokens(maticBalance, [PGOV, MATIC], account, chain.time() + 60, {"from": account})

        message = f"[MATIC/PGOV]: maticBalance: {maticBalance/1e18}, pgovBalance: {pgovBalance/1e18}, ratio: {ratio}. Working...";

        print(message)
    except Exception as e:
        print("e", e)

    time.sleep(30)