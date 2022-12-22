from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
# deployer = accounts[2]

description = "OOIP-17-itoken-collateral"

targets = []
values = []
calldatas = []


tx_list = []
tickMathV1 = TickMathV1.at("0xae0886d167ccf942c4dad960f5cfc9c3c7a2816e")
liquidationHelper = LiquidationHelper.at("0xcfe69c933a941613f752ab0e255af0ef20cb958b")
volumeTracker = VolumeTracker.at("0xff00e3da71d76f85dcaf9946a747463c8bfa153f")
lo = LoanOpenings.at("0xf426f2609784541653cc351485592e82e57dcb58")
ls = LoanSettings.at("0xbd4881da92f764e4d7bdd7ef79af0c6585165f64")
ps = ProtocolSettings.at("0xcec233590474c4d216271bfc0b507cbd40df73ea")
lcs= LoanClosingsLiquidation.at("0xbcd11e4f7e8a539f9c6fe91dc573ea5bf31aa7f0") # not verified
lc = LoanClosings.at("0xe7121af07d832d49a5a0adf561924c505997181e")
lm = LoanMaintenance.at("0x91fcdb277e84642ef29db708ff35aa48ba20f04d")
se = SwapsExternal.at("0xe9aa2a8a7d14fc7ca879fb8aa0e8512231009c14")
itokenImpl = LoanTokenLogicStandard.at("0x624f7f89414011b276c60ea2337bfba936d1cbbe")
itokenImplWeth = LoanTokenLogicWeth.at("0x9712dc729916e154daa327c36ad1b9f8e069fba1")
price_feed_new = PriceFeeds.at("0x09Ef93750C5F33ab469851F022C1C42056a8BAda")  # not verified

tx_list.append([BZX, BZX.replaceContract.encode_input(lo)])
tx_list.append([BZX, BZX.replaceContract.encode_input(ls)])
tx_list.append([BZX, BZX.replaceContract.encode_input(ps)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lcs)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lc)])
tx_list.append([BZX, BZX.replaceContract.encode_input(lm)])
tx_list.append([BZX, BZX.replaceContract.encode_input(se)])
tx_list.append([BZX, BZX.setPriceFeedContract.encode_input(price_feed_new)])

list = TOKEN_REGISTRY.getTokens(0, 100)
for l in list:
    iToken = Contract.from_abi("LoanTokenLogicStandard", address=l[0], abi=interface.IToken.abi)
    # those are owned by the guardian
    if (iToken == iOOKI):
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


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)
