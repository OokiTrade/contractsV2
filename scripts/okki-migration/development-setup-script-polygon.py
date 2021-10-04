#!!!!! For development & testing only
assert (network.show_active().find("-fork")>=0)
#OOKI
OOKI = OokiToken.deploy({'from': accounts[0]})
exec(open("./scripts/okki-migration/stop-farming-deploy-migrator-polygon.py").read())
OOKI.transferOwnership(deployer,{'from': accounts[0]})
OOKI.mint(govOokiConverter, 1e26, {'from': deployer})

print("OOKI: ", OOKI)




