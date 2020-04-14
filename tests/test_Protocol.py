#!/usr/bin/python3

import pytest

def test_targetSetup(Constants, FuncSigs, bzx):
    
    sigs = [
        FuncSigs["setupLoanParams"],
        FuncSigs["disableLoanParams"]
    ]
    targets = [Constants["ONE_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(FuncSigs["setupLoanParams"]) == Constants["ONE_ADDRESS"]
    assert bzx.getTarget(FuncSigs["disableLoanParams"]) == Constants["ONE_ADDRESS"]

    targets = [Constants["ZERO_ADDRESS"]] * len(sigs)
    bzx.setTargets(sigs, targets)

    assert bzx.getTarget(FuncSigs["setupLoanParams"]) == Constants["ZERO_ADDRESS"]
    assert bzx.getTarget(FuncSigs["disableLoanParams"]) == Constants["ZERO_ADDRESS"]
