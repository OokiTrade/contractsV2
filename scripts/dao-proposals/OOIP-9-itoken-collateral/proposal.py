exec(open("./scripts/env/set-eth.py").read())
import math
from brownie import *

# def main():

# deployer = accounts.at("0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6", True)
deployer = accounts[2]

description = "OOIP-8"




targets = []
values = []
calldatas = []
# 1. Activate new Staking
gas_price = Wei("100 gwei")
deployer.transfer(TEAM_VOTING_MULTISIG, Wei("10 ether"), gas_price=gas_price)




# 3. iToken as collateral
supportedITokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)

# a. deploy price feeds
iTokenPriceFeeds = []
iTokens = []
for tokenAssetPair in supportedITokenAssetsPairs:
    iToken = tokenAssetPair[0]
    # skip deploying iOOKI as collateral since no price feed
    if iToken == iOOKI.address or iToken == iBZRX.address:
        continue
    iTokens.append(iToken)
    underlying = tokenAssetPair[1]
    underlyingPriceFeed = PRICE_FEED.pricesFeeds(underlying)

    iTokenPriceFeed = deployer.deploy(PriceFeedIToken, underlyingPriceFeed, iToken, gas_price=gas_price)
    iTokenPriceFeeds.append(iTokenPriceFeed)

calldata = PRICE_FEED.setPriceFeed.encode_input(iTokens, iTokenPriceFeeds)
targets.append(PRICE_FEED)
calldatas.append(calldata)

# b. update iToken as collateral
base_data = [
    b"0x0",  # id
    False,  # active
    str(TIMELOCK),  # owner
    "0x0000000000000000000000000000000000000001",  # loanToken
    "0x0000000000000000000000000000000000000002",  # collateralToken
    Wei("20 ether"),  # minInitialMargin
    Wei("15 ether"),  # maintenanceMargin
    0  # fixedLoanTerm
]

params = []
LOWER_ADMIN = Contract.from_abi("LOWER_ADMIN", "0x47627cB1f5dcaBEAC41641b5950312236f9325Db", LoanTokenSettingsLowerAdmin.abi)

# for each iToken build a list of base_data with iToken as collateral.
for tokenAssetPair in supportedITokenAssetsPairs[0:len(supportedITokenAssetsPairs)-8]:
    iToken_deployed = tokenAssetPair[0]
    underlying = tokenAssetPair[1]
    # we don't allow iOOKI as collateral since no price feed
    if iToken_deployed == iOOKI.address or iToken_deployed == iBZRX.address:
        continue

    for iToken_collateral in iTokens:
        # we don't allow iUSDT.marginTrade( iUSDT as collateral)
        if iToken_deployed == iToken_collateral:
            continue

        base_data_copy = base_data.copy()

        base_data_copy[3] = underlying
        base_data_copy[4] = iToken_collateral # pair is iToken, Underlying
        print(base_data_copy)
        params.append(base_data_copy)

    iToken_deployed = Contract.from_abi("iToken_deployed", address=iToken_deployed, abi=LoanTokenLogicStandard.abi)
    calldata = LOWER_ADMIN.setupLoanParams.encode_input(params, True)
    calldata = iToken_deployed.updateSettings.encode_input(LOWER_ADMIN.address, calldata)

    targets.append(iToken_deployed)
    calldatas.append(calldata)
    params.clear()


# # 4. TODO redeploy old staking to exit() vesting
# stakingImpl = deployer.deploy(StakingV1_1)
# stakingProxy = Contract.from_abi("proxy", STAKING_OLD, StakingProxy.abi)
# calldata = stakingProxy.replaceImplementation.encode_input(stakingImpl)
# targets.append(STAKING_OLD)
# calldatas.append(calldata)

# # 5. TODO allocate funds for audit - 40k
# # considering ooki price 0.016 = 2500000 ooki
# AUDIT_OOKI_AMOUNT = 2500000

# # 6. make Drypto and Suz bonus bigger - funds already allocated
# # 7. Allocate funds for option strategy (1 year allocation) (5m$ montly) (6 months)
# RIBBON_OOKI_AMOUNT=312500000

# # 8. TIDAL allocation 10k
# TIDAL_OOKI_AMOUNT = 625000

# #  5 6 7
# calldata = OOKI.transfer.encode_input(INFRASTRUCTURE_MULTISIG, (AUDIT_OOKI_AMOUNT+RIBBON_OOKI_AMOUNT+TIDAL_OOKI_AMOUNT) * 10**18)

# targets.append(OOKI)
# calldatas.append(calldata)






values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1, "gas_price": gas_price})

