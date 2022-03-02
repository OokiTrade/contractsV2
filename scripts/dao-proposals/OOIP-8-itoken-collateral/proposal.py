from brownie import *
import math
exec(open("./scripts/env/set-eth.py").read())

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-8"
OOKI_PRICE = 0.014  # approximate price. lefties will be returned to treasury


targets = []
values = []
calldatas = []


# 1. redeploy old staking to exit() vesting
stakingImpl = deployer.deploy(StakingV1_1)
stakingProxy = Contract.from_abi("proxy", STAKING_OLD, StakingProxy.abi)
calldata = stakingProxy.replaceImplementation.encode_input(stakingImpl)
targets.append(STAKING_OLD)
calldatas.append(calldata)


# 2. allocate funds for code4rena audit 40k$
AUDIT_OOKI_AMOUNT = 40000 / OOKI_PRICE


# 3. make Drypto and Suz bonus bigger
# 4. Employ Frank 14k USD/year, 100k OOKI/year
# 5. Allocate funds for option strategy (5m$ total) ribbon
RIBBON_OOKI_AMOUNT = 5000000 / OOKI_PRICE


# 6. TIDAL allocation 10k
TIDAL_OOKI_AMOUNT = 10000 / OOKI_PRICE


# 7. Allocate funds for Olimpus Pro 2m$ for SLP(ETH/OOKI) 1m$ for USD treasury diversificatino
OLIMPUS_PRO = 3000000 / OOKI_PRICE


# 8. Allocate funds for Kyber liquidity mining (15k$ for 3 months)
KYBER_POLYGON_LIQUIDITY = 45000 / OOKI_PRICE


# 2 5 7 8
calldata = OOKI.transfer.encode_input(INFRASTRUCTURE_MULTISIG, (AUDIT_OOKI_AMOUNT+RIBBON_OOKI_AMOUNT +
                                      TIDAL_OOKI_AMOUNT + OLIMPUS_PRO + KYBER_POLYGON_LIQUIDITY) * 10**18)

targets.append(OOKI)
calldatas.append(calldata)


values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {
            'from': TEAM_VOTING_MULTISIG, "required_confs": 1, "gas_price": gas_price})
