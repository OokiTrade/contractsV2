deployer = accounts[0]

ookiImpl = deployer.deploy(OokiToken)
ookiProxy = deployer.deploy(OokiOwnableProxy, ookiImpl, b"")

ooki = Contract.from_abi("ooki", ookiProxy, OokiToken.abi)


assert ooki.owner() == deployer
assert ooki.symbol() == "OOKI"

ooki.initialize({"from": deployer})
# testing upgrade

ookiUpgrade = deployer.deploy(OokiToken)

ookiProxy.upgradeTo(ookiUpgrade, {"from": deployer})

assert ooki.name() == "Ooki Token"