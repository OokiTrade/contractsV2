deployer = accounts[0]

ookiImpl = deployer.deploy(OokiToken)
ookiProxy = deployer.deploy(Proxy_0_8, ookiImpl)

ooki = Contract.from_abi("ooki", ookiProxy, OokiToken.abi)


assert ooki.owner() == deployer
assert ooki.symbol() == "OOKI"

ooki.initialize({"from": deployer})
# testing upgrade

ookiUpgrade = deployer.deploy(OokiToken)

ookiProxy.replaceImplementation(ookiUpgrade, {"from": deployer})

assert ooki.name() == "Ooki Token"

ooki.mint(accounts[0], 10e18, {"from": accounts[0]})

assert ooki.balanceOf(accounts[0]) == 10e18
ooki.burn(5e18, {"from": accounts[0]})

assert ooki.balanceOf(accounts[0]) == 5e18