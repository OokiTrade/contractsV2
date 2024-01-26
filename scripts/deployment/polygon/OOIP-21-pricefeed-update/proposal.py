from brownie import *
exec(open("./scripts/env/set-matic.py").read())
tx_list = []
for l in list:
    iToken = Contract.from_abi("IToken", address=l[0], abi=interface.IToken.abi)
    if (iToken == iETH):
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImplWeth)])
        # iToken.setTarget(itokenImplWeth,{"from": GUARDIAN_MULTISIG})
    else:
        tx_list.append([iToken, iToken.setTarget.encode_input(itokenImpl)])
        # iToken.setTarget(itokenImpl,{"from": GUARDIAN_MULTISIG})
    tx_list.append([iToken, iToken.consume.encode_input(2**256-1)])
    # iToken.consume(2**256-1, {"from": GUARDIAN_MULTISIG})

tx_list.append([BZX, BZX.replaceContract.encode_input(lcl.address)])
# BZX.replaceContract(lcl,{"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.replaceContract.encode_input(lc.address)])
# BZX.replaceContract(lc,{"from": GUARDIAN_MULTISIG})
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed.address)])
# BZX.setPriceFeedContract(price_feed, {"from": GUARDIAN_MULTISIG})