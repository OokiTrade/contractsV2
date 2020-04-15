#!/usr/bin/python3

import pytest

def test_targetSetup(Constants, FuncSigs, bzx):
    
    sigs = [
        FuncSigs["LoanSettings"]["setupLoanParams"],
        FuncSigs["LoanSettings"]["disableLoanParams"]
    ]
    targets = [Constants["ONE_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(FuncSigs["LoanSettings"]["setupLoanParams"]) == Constants["ONE_ADDRESS"]
    assert bzx.getTarget(FuncSigs["LoanSettings"]["disableLoanParams"]) == Constants["ONE_ADDRESS"]

    targets = [Constants["ZERO_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(FuncSigs["LoanSettings"]["setupLoanParams"]) == Constants["ZERO_ADDRESS"]
    assert bzx.getTarget(FuncSigs["LoanSettings"]["disableLoanParams"]) == Constants["ZERO_ADDRESS"]
