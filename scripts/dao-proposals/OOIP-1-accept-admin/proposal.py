exec(open("./scripts/env/set-eth.py").read())

proposerAddress = "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
# should run `DAO.__setPendingLocalAdmin(TIMELOCK, {'from': bzxOwner})`
# should run `DAO.__acceptAdmin({'from': bzxOwner})`
# should run `STAKING.setGovernor(DAO, {'from': bzxOwner})` - not to forget

calldata = DAO.__acceptLocalAdmin.encode_input()
DAO.propose([DAO], [0], [""], [calldata], "DAO.__acceptLocalAdmin()", {'from': proposerAddress})