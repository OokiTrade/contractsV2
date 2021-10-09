exec(open("./scripts/env/set-eth.py").read())

acct = accounts.at("0x54e88185eb636c0a75d67dccc70e9abe169ba55e", True)

description = "Upgrade DAO, Staking, maintenance and B.Protocol"


DAOGuardiansMultisig = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"

targets = []
values = []
calldatas = []

# 1. upgrade DAO implementation
daoImpl = acct.deploy(GovernorBravoDelegate)
daoProxy = Contract.from_abi("GovernorBravoDelegator", address=DAO, abi=GovernorBravoDelegator.abi) # attire proxy interface
calldata = daoProxy._setImplementation.encode_input(daoImpl)
targets.append(daoProxy)
calldatas.append(calldata)

# 2. upgrade STAKING implementation
stakingImpl = acct.deploy(StakingV1_1)
stakingProxy = Contract.from_abi("STAKING", STAKING, StakingProxy.abi) # attire proxy interface
calldata = stakingProxy.replaceImplementation.encode_input(stakingImpl)
targets.append(stakingProxy)
calldatas.append(calldata)

# 3. BZX.setTargets(...)
calldata = BZX.setTargets.encode_input(["swapExternalWithGasToken(address,address,address,address,address,uint256,uint256,bytes)"], ["0x0000000000000000000000000000000000000000"])
targets.append(BZX)
calldatas.append(calldata)

# 4. BZX.setLoanPool(...)
calldata = BZX.setLoanPool.encode_input([iLEND], ["0x0000000000000000000000000000000000000000"])
targets.append(BZX)
calldatas.append(calldata)

# 5. BZRX.transferFrom(Timelock, 0x2a599cEba64CAb8C88549c2c7314ea02A161fC70)
BZRXAmount = 250000*1e18 # 250k BZRX
calldata = BZRX.transfer.encode_input(DAOGuardiansMultisig, BZRXAmount)
targets.append(BZRX)
calldatas.append(calldata)

# 6. BZBZX.replaceContract to deploy ProtocolPausableGuardian module
pausableGuardianImpl = acct.deploy(ProtocolPausableGuardian)
calldata = BZX.replaceContract.encode_input(pausableGuardianImpl)
targets.append(BZX)
calldatas.append(calldata)

# 7. bzx.setLoanPool([iOOKI], [OOKI])
OOKI = "0xC5c66f91fE2e395078E0b872232A20981bc03B15"
iOOKI = "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da"
calldata = BZX.setLoanPool.encode_input([iOOKI], [OOKI])
targets.append(BZX)
calldatas.append(calldata)

# 8. bzx.setSupportedTokens([OOKI], [True])
calldata = BZX.setSupportedTokens.encode_input([OOKI], [True], True)
targets.append(BZX)
calldatas.append(calldata)

# 9. bzx.setLiquidationIncentivePercent(...) 
loanTokens = []
collateralTokens = []
amounts = []
iTokens = BZX.getLoanPoolsList(0, 30)
for iToken in iTokens:
    loanTokens.append(iToken)
    collateralTokens.append(BZX.loanPoolToUnderlying(iToken))
    amounts.append(7*1e18)
calldata = BZX.setLiquidationIncentivePercent.encode_input(loanTokens, collateralTokens, amounts)
targets.append(BZX)
calldatas.append(calldata)



values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': acct})
