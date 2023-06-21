tvl = 0
stakingTvl = 0
ethPrice = SUSHI_ROUTER.getAmountsOut(1 * 10 ** WETH.decimals(), [WETH, USDT])[1] / 10 ** USDT.decimals()
print("ETH price: ", ethPrice, "USD")
for x in list:
    token = interface.ERC20(x[1])
    itoken = interface.ERC20(x[0])
    if(token == KNC):
        continue

    path = [token, USDC]
    if(token.address == WBTC):
        path = [token, WETH]

    price = (SUSHI_ROUTER.getAmountsOut(1 * 10 ** token.decimals(), [token, WETH])[1]) / 10 ** WETH.decimals() if(token.address != WETH) else 1
    balance1 = token.balanceOf(itoken) / 10 ** token.decimals()
    balance2 = token.balanceOf(BZX) / 10 ** token.decimals()
    stakingTvl = stakingTvl + price * token.balanceOf(STAKING) / 10 ** token.decimals()

    ttvl = (balance1 + balance2) * price
    symbol = token.symbol() if(token.address != MKR.address) else "MKR"
    print (symbol, ":", "(",balance1,"+",balance2,") * ", price, " = ", ttvl, "ETH (",ttvl * ethPrice," USD)")
    tvl = tvl + ttvl



print("tvl from token: ", tvl, "ETH (",tvl * ethPrice," USD)")
print("tvl from staking: ", stakingTvl, "ETH (",stakingTvl * ethPrice," USD)")
print("Total: ", tvl + stakingTvl, "ETH (",(tvl + stakingTvl)* ethPrice," USD)")
