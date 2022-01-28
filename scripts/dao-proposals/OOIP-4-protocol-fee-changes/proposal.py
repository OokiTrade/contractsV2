exec(open("./scripts/env/set-eth.py").read())
import math

def main():

    acct = accounts.at("0x54e88185eb636c0a75d67dccc70e9abe169ba55e", True)

    description = "Intoduce Flash Loan Fees"


    DAOGuardiansMultisig = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"

    targets = []
    values = []
    calldatas = []

    iTokens = BZX.getLoanPoolsList(0, 30)

    # 1. upgrade LoanToken implementations
    loanTokenLogicImpl = "" # acct.deploy(LoanTokenLogicStandard)
    for iToken in iTokens:
        iTokenProxy = Contract.from_abi("LoanToken", iToken, LoanToken.abi) # attire proxy interface
        calldata = iTokenProxy.setTarget.encode_input(loanTokenLogicImpl)
        targets.append(iTokenProxy)
        calldatas.append(calldata)
        calldataSetFee = iTokenProxy.updateFlashBorrowFeePercent.encode_input(int(0.03e18)) #set to 0.03% in WEI Precision
        targets.append(iTokenProxy)
        calldata.append(calldataSetFee)

    # 2. upgrade PROTOCOL implementation
    flashBorrowFeeImpl = "" # acct.deploy(FlashBorrowFeesHelper)
    calldata = BZX.replaceContract.encode_input(flashBorrowFeeImpl)
    targets.append(BZX)
    calldatas.append(calldata)

    values = [0] * len(targets)  # empty array
    signatures = [""] * len(targets)  # empty signatures array


    # Make proposal
    DAO.propose(targets, values, signatures, calldatas, description, {'from': acct, "required_confs": 0})

