deployer = accounts[0]

ookiImpl = deployer.deploy(OokiToken)

ookiProxyTom = deployer.deploy(OokiTokenProxy, ookiImpl)
ookiTom = Contract.from_abi("ooki", ookiProxyTom, OokiToken.abi)


ookiProxyZeppelin = deployer.deploy(OokiOwnableProxy, ookiImpl, b"")

ookiZeppelin = Contract.from_abi("ooki", ookiProxyZeppelin, OokiToken.abi)


print("mint")
ookiTom.mint(accounts[1], 10e18, {"from": accounts[0]})
tomMint =  history[-1].gas_used

ookiZeppelin.mint(accounts[1], 10e18, {"from": accounts[0]})
zeppelinMint = history[-1].gas_used


ookiTom.transfer(accounts[2], 5e18, {"from": accounts[1]})
tomTransfer =  history[-1].gas_used

ookiZeppelin.transfer(accounts[2], 5e18, {"from": accounts[1]})
zeppelinTransfer =  history[-1].gas_used


print("TomMint:", tomMint)
print("zeppelinMint:", zeppelinMint)

print("tomTransfer:", tomTransfer)
print("zeppelinTransfer:", zeppelinTransfer)