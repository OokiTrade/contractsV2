from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-21-pricefeed-update"
targets = []
values = []
calldatas = []
tx_list = []

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)

    if (iToken.address.lower() == "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da".lower()):
        #Under GUARDIAN_MULTISIG
        print("iOOKI will be upgraded by GUARDIAN")
        continue
    if (iToken == iETH):
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
    else:
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])

iTokens = [item[0] for item in list]
tx_list.append([BZX, BZX.setSupportedTokens.encode_input(iTokens, [True] * len(iTokens), True)])

for tx in tx_list:
    targets.append(tx[0].address)
    calldatas.append(tx[1])

##ToDo: disable iLRC
##ToDo: reinit iOOKI

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
