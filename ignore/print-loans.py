exec(open("./scripts/env/set-eth.py").read())
import time

loans = []
for i in range(0, BZX.getActiveLoansCount()):
    try:
        loan = BZX.getActiveLoans(i, 1, False)
        loans.append(loan)
        print(i)
    except Exception as e:
        print(i, "error")
        pass
    time.sleep(1)


totalCollateral = {}
for l in loans:
    colateralAddress = l[0][3]
    colateralAmount = l[0][5]

    if colateralAddress not in totalCollateral:
        totalCollateral[colateralAddress] = 0
    totalCollateral[colateralAddress] = totalCollateral[colateralAddress] + colateralAmount

print("name collateralAddress collateralAmount BZXBalance, diff")
for t in totalCollateral:
    underlying = Contract.from_abi("a", address=t, abi=interface.ERC20.abi)
    if underlying == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2":
        # print("underlying", underlying)
        symbol = "MKR"
    else:
        symbol = underlying.symbol()
        
    bzxBalance = underlying.balanceOf(BZX)
    diff = bzxBalance - totalCollateral[t]
    print(symbol, t, totalCollateral[t], bzxBalance, diff)

print("lending")
print("name collateralAddress held paid")
for t in totalCollateral:
    underlying = Contract.from_abi("a", address=t, abi=interface.ERC20.abi)
    if underlying == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2":
        # print("underlying", underlying)
        symbol = "MKR"
    else:
        symbol = underlying.symbol()
    held = BZX.lendingFeeTokensHeld(underlying)
    paid = BZX.lendingFeeTokensPaid(underlying)
    
    print(symbol, t, held, paid)
    time.sleep(1)

print("borrowing")
print("name collateralAddress held paid")
for t in totalCollateral:
    underlying = Contract.from_abi("a", address=t, abi=interface.ERC20.abi)
    if underlying == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2":
        # print("underlying", underlying)
        symbol = "MKR"
    else:
        symbol = underlying.symbol()
        
    held = BZX.borrowingFeeTokensHeld(underlying)
    paid = BZX.borrowingFeeTokensPaid(underlying)
    
    print(symbol, t, held, paid)
    time.sleep(1)

print("trading")
print("name collateralAddress held paid")
for t in totalCollateral:
    underlying = Contract.from_abi("a", address=t, abi=interface.ERC20.abi)
    if underlying == "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2":
        # print("underlying", underlying)
        symbol = "MKR"
    else:
        symbol = underlying.symbol()
        
    held = BZX.tradingFeeTokensHeld(underlying)
    paid = BZX.tradingFeeTokensPaid(underlying)
    
    print(symbol, t, held, paid)
    time.sleep(1)
