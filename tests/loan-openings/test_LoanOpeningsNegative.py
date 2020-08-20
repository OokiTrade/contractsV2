#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId

# def test_borrowOrTradeFromPoolLoanDataBytesRequiredWithEther(Constants, bzx):
#     with reverts("loanDataBytes required with ether"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolNotAuthorized(Constants, bzx):
#     with reverts("not authorized"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanParamsNotExist(Constants, bzx):
#     with reverts("loanParams not exists"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolCollateralIsZero(Constants, bzx):
#     with reverts("collateral is 0"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_setDelegatedManagerUnauthorized(Constants, bzx):
#     with reverts("unauthorized"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolCollateralLoanMatch(Constants, bzx):
#     with reverts("collateral/loan match"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolInitialMarginTooLow(Constants, bzx):
#     with reverts("initialMargin too low"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolInvalidInterest(Constants, bzx):
#     with reverts("invalid interest"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanParamsDisabled(Constants, bzx):
#     with reverts("loanParams disabled"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanExists(Constants, bzx):
#     with reverts("loan exists"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanHasEnded(Constants, bzx):
#     with reverts("loan has ended"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolBorrowerMismatch(Constants, bzx):
#     with reverts("borrower mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLenderMismatch(Constants, bzx):
#     with reverts("lender mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanParamMismatch(Constants, bzx):
#     with reverts("loanParams mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolSurplusLoanToken(Constants, bzx):
#     with reverts("surplus loan token"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolCollateralInsuficient(Constants, bzx):
#     with reverts("collateral insufficient"):
#         bzx.borrowOrTradeFromPool(0, 0)
