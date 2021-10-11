exec(open("./scripts/env/set-eth.py").read())
import math

def main():

    acct = accounts.at("0x54e88185eb636c0a75d67dccc70e9abe169ba55e", True)

    description = "Upgrade DAO, Staking, maintenance and B.Protocol"


    DAOGuardiansMultisig = "0x2a599cEba64CAb8C88549c2c7314ea02A161fC70"

    targets = []
    values = []
    calldatas = []

    # 1. upgrade DAO implementation
    daoImpl = "0xb7A0B67fF67B548e91953647F8cDd7647660279d" # acct.deploy(GovernorBravoDelegate)
    daoProxy = Contract.from_abi("GovernorBravoDelegator", address=DAO, abi=GovernorBravoDelegator.abi) # attire proxy interface
    calldata = daoProxy._setImplementation.encode_input(daoImpl)
    targets.append(daoProxy)
    calldatas.append(calldata)

    # 2. upgrade STAKING implementation
    stakingImpl = "0xB01f6163bc6a715765EE69f91043caE5a617F3a2" # acct.deploy(StakingV1_1)
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
    BZRXAmount = 250000*10**18 # 250k BZRX
    # TotalSupply: 185416043.744399669180168401 PGOV and 252681074.289343767474252583 BGOV
    BZRXBuyoutAmount = math.ceil((185416043.744399669180168401 + 252681074.289343767474252583)/20) * 10**18 # 21,904,856 ~21.9m

    calldata = BZRX.transfer.encode_input(DAOGuardiansMultisig, BZRXAmount + BZRXBuyoutAmount)
    targets.append(BZRX)
    calldatas.append(calldata)

    # 6. BZBZX.replaceContract to deploy ProtocolPausableGuardian module
    pausableGuardianImpl = "0x4dE206295983D6B281556145e1D8915D0Dc390D8" # acct.deploy(ProtocolPausableGuardian)
    calldata = BZX.replaceContract.encode_input(pausableGuardianImpl)
    targets.append(BZX)
    calldatas.append(calldata)

    # # 7. bzx.setLoanPool([iOOKI], [OOKI])
    # OOKI = "0xC5c66f91fE2e395078E0b872232A20981bc03B15"
    # iOOKI = "0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da"
    # calldata = BZX.setLoanPool.encode_input([iOOKI], [OOKI])
    # targets.append(BZX)
    # calldatas.append(calldata)

    # # 8. bzx.setSupportedTokens([OOKI], [True])
    # calldata = BZX.setSupportedTokens.encode_input([OOKI], [True], True)
    # targets.append(BZX)
    # calldatas.append(calldata)

    # # 9. bzx.setLiquidationIncentivePercent(...) 
    # loanTokens = []
    # collateralTokens = []
    # amounts = []
    # iTokens = BZX.getLoanPoolsList(0, 30)
    # for iToken in iTokens:
    #     loanTokens.append(iToken)
    #     collateralTokens.append(BZX.loanPoolToUnderlying(iToken))
    #     amounts.append(7*1e18)
    # calldata = BZX.setLiquidationIncentivePercent.encode_input(loanTokens, collateralTokens, amounts)
    # targets.append(BZX)
    # calldatas.append(calldata)

    # acct.deploy(StakingAdminSettings)
    stakingAdminSettings = Contract.from_abi("stakingAdminSettings", "0x83f8BA6B6472820CF5C0087990c1e7f4E744Df48", StakingAdminSettings.abi)
    POOL3Gauge = Contract.from_abi("POOL3Gauge", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi)
    POOL3 = Contract.from_abi("POOL3", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)

    calldata = stakingAdminSettings.setApprovals.encode_input(POOL3, POOL3Gauge, 2**256-1)
    calldata = STAKING.updateSettings.encode_input(stakingAdminSettings, calldata)
    targets.append(STAKING)
    calldatas.append(calldata)

    # stakingVoteDelegatorImpl = acct.deploy(StakingVoteDelegator)
    # acct.deploy(Proxy_0_5, stakingVoteDelegatorImpl)
    stakingVoteDelegatorProxy = Contract.from_abi("stakingAdminSettings", "0x7e9d7A0ff725f88Cc6Ab3ccF714a1feA68aC160b", StakingVoteDelegator.abi)
    calldata = stakingAdminSettings.setVoteDelegator.encode_input(stakingVoteDelegatorProxy.address)
    calldata = STAKING.updateSettings.encode_input(stakingAdminSettings, calldata)
    targets.append(STAKING)
    calldatas.append(calldata)

    # #this will trigger deposit to curve, otherwise claim() will fail, because it will try to withdraw from pool
    # TODO STAKING.claimCrv({'from': res.owner()})

    values = [0] * len(targets)  # empty array
    signatures = [""] * len(targets)  # empty signatures array


    # Make proposal
    DAO.propose(targets, values, signatures, calldatas, description, {'from': acct, "required_confs": 0})

