from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-21-pricefeed-update"
targets = []
values = []
calldatas = []
tx_list = []

for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    if (l[1] == OOKI.address):
        print("iOOKI will be upgraded by GUARDIAN")
        continue
    if (iToken == iETH):
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
        #iToken.setTarget(itokenImplWeth,{"from": TIMELOCK})
    else:
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])
        #iToken.setTarget(itokenImpl,{"from": TIMELOCK})
    tx_list.append([iToken, iToken.consume.encode_input(2**256-1)])
    #iToken.consume(2**256-1, {"from": TIMELOCK})

tx_list.append([BZX, BZX.replaceContract.encode_input(lcl.address)])
#BZX.replaceContract(lcl,{"from": TIMELOCK})
tx_list.append([BZX, BZX.replaceContract.encode_input(lc.address)])
#BZX.replaceContract(lc,{"from": TIMELOCK})
tx_list.append([BZX, BZX.replaceContract.encode_input(fbh.address)])
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed.address)])
#BZX.setPriceFeedContract(price_feed, {"from": TIMELOCK})
tx_list.append([DAO, DAO.__setQuorumPercentage.encode_input(DAO.MIN_QUORUM_PERCENTAGE())])
#DAO.__setQuorumPercentage(DAO.MIN_QUORUM_PERCENTAGE(), {'from': TIMELOCK})
tx_list.append([BZRX, BZRX.approve.encode_input(DAO_FUNDING, 45000000e18)])

for tx in tx_list:
    targets.append(tx[0].address)
    calldatas.append(tx[1])

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array

# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': ""})
print("call", call)
