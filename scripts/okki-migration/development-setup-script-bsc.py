#!!!!! For development & testing only
assert (network.show_active().find("-fork")>=0)

exec(open("./scripts/okki-migration/deploy-migrator-bsc.py").read())

BZRX.transfer(govOokiConverter, 100000e18, {'from': BZX})



