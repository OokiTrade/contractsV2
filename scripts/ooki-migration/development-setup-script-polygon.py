#!!!!! For development & testing only
assert (network.show_active().find("-fork")>=0)

exec(open("./scripts/ooki-migration/stop-farming-deploy-migrator-polygon.py").read())

BZRX.transfer(govConverter, 100000e18, {'from': BZX})



