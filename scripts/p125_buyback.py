import schedule
import time

deployer = accounts.load("buyback")
exec(open("./scripts/env/set-matic.py").read())
buyback = Contract.from_abi("buyback","0x12ebd8263a54751aaf9d8c2c74740a8e62c0afbe",BuyBackAndBurn.abi)

amount = USDC.balanceOf(buyback)
if(amount == 0):
    exit(0)
percent = 100e6 * 1e18/amount * 100

def job():
    buyback.buyBack(percent, {'from': deployer})

schedule.every().hour.do(job)

while True:
    schedule.run_pending()
    time.sleep(1)
