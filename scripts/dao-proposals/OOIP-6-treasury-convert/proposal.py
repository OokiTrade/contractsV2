exec(open("./scripts/env/set-eth.py").read())
exec(open("./scripts/env/common-functions.py").read())
import math

# def main():

acct = accounts.at("0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e", True)

description = "Preparation for rebrand, Treasury convert, add iOOKI"


targets = []
values = []
calldatas = []

# 1. BZRX_CONVERTER.convert(TIMELOCK, BZRX.balanceOf(TIMELOCK), {'from': TIMELOCK})
bzrxAmount = BZRX.balanceOf(TIMELOCK)

# approval for spending by converter
calldata = BZRX.approve.encode_input(BZRX_CONVERTER, bzrxAmount)
targets.append(BZRX)
calldatas.append(calldata)

calldata = BZRX_CONVERTER.convert.encode_input(TIMELOCK, bzrxAmount)
targets.append(BZRX_CONVERTER)
calldatas.append(calldata)


# 2. BZX.setFeeController(address(0))
calldata = BZX.setFeesController.encode_input(ZERO_ADDRESS)
targets.append(BZX)
calldatas.append(calldata)


# 3. bzx.setBorrowingFeePercent(0)
calldata = BZX.setBorrowingFeePercent.encode_input(0)
targets.append(BZX)
calldatas.append(calldata)

# 4. bzx.setLoanPool([iOOKI], [OOKI])
OOKI = "0x0De05F6447ab4D22c8827449EE4bA2D5C288379B"
iOOKI = "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da"
calldata = BZX.setLoanPool.encode_input([iOOKI], [OOKI])
targets.append(BZX)
calldatas.append(calldata)

# 5. bzx.setSupportedTokens([OOKI], [True])
calldata = BZX.setSupportedTokens.encode_input([OOKI], [True], True)
targets.append(BZX)
calldatas.append(calldata)

# 6. bzx.setLiquidationIncentivePercent(...) 

loanTokens = []
collateralTokens = []
amounts = []
iTokens = BZX.getLoanPoolsList(0, 30)
for iToken in iTokens:
    loanTokens.append(iToken)
    collateralTokens.append(OOKI)
    amounts.append(7*1e18)
    
calldata = BZX.setLiquidationIncentivePercent.encode_input(loanTokens, collateralTokens, amounts)
targets.append(BZX)
calldatas.append(calldata)




values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
calldata = DAO.propose.encode_input(targets, values, signatures, calldatas, description)
safe = ApeSafe(TEAM_VOTING_MULTISIG)

