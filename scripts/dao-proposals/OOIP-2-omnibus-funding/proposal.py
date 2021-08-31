exec(open("./scripts/env/set-eth.py").read())

proposerAddress = "0x54e88185eb636c0a75d67dccc70e9abe169ba55e"

description = "Setup for DAO Omnibus Funding"


marketingMultisig = "0xddD5105b94A647eEa6776B5A63e37D81eAE3566F"
infrastructureMultisig = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"
daoFundingContract = "0x37cBA8d1308019594621438bd1527E5A6a34B49F"

# calculate BZRX amount assuming 0.4$ per BZRX
marketingMultisigAmount = 150000 / 0.4 * 1e18
infrastructureMultisigAmount = 15000 / 0.4 * 1e18


# no unlimited approval, as a safety measure
daoFundingContractApprovalAmount = 4000000 / 0.4 * 1e18

targets = []
values = []
calldatas = []

#  1. Transfer 150k$ BZRX to Marketing Multisig
calldata = BZRX.transfer.encode_input(
    marketingMultisig, marketingMultisigAmount)
targets.append(BZRX)
calldatas.append(calldata)


#  2. Transfer 150k$ BZRX to Marketing Multisig
calldata = BZRX.transfer.encode_input(
    infrastructureMultisig, infrastructureMultisigAmount)
targets.append(BZRX)
calldatas.append(calldata)

# 3. 1 Year aproval for DAO FundingContract
calldata = BZRX.approve.encode_input(
    daoFundingContract, daoFundingContractApprovalAmount)
targets.append(BZRX)
calldatas.append(calldata)

values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas,
            description, {'from': acct})
