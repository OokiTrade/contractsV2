exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts[2]
from ape_safe import ApeSafe

safe = ApeSafe(GUARDIAN_MULTISIG)
# tickMath = TickMathV1.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})


# loanMaintenance_Arbitrum = LoanMaintenance.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# loanClosings_Arbitrum = LoanClosings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# swapsImpl = SwapsExternal.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# receiver = Receiver.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
tickMath = Contract.from_abi("TickMathV1", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", TickMathV1.abi)
loanMaintenance_Arbitrum = Contract.from_abi("LoanMaintenance", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanMaintenance.abi)
loanMaintenance_2 = Contract.from_abi("LoanMaintenance_2", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanMaintenance_2.abi)
loanOpenings = Contract.from_abi("LoanOpenings", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanOpenings.abi)
loanClosings_Arbitrum = Contract.from_abi("LoanClosings", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanClosings.abi)
loanSettings = Contract.from_abi("LoanSettings", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanSettings.abi)
swapsImpl = Contract.from_abi("SwapsExternal", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", SwapsExternal.abi)
receiver = Contract.from_abi("Receiver", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", Receiver.abi)

loanTokenLogicStandard = Contract.from_abi("LoanTokenLogicStandard", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanTokenLogicStandard.abi)
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", "0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1", LoanTokenLogicWeth.abi)

ookiPriceFeed = Contract.from_abi("OOKIPriceFeed", "0xA8DCa6006921bE2993AB41FA41A1634Dc20070Dd", OOKIPriceFeed.abi)
helperImpl = Contract.from_abi("HelperImpl", "0x04f5088268fa1bf8a0fa20dbf5b538d70d6ef708", HelperImpl.abi)

# BZX.replaceContract(loanMaintenance_Arbitrum, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanClosings_Arbitrum, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(receiver, {"from": GUARDIAN_MULTISIG})
arr = []
arr.append([BZX, BZX.replaceContract.encode_input(loanMaintenance_Arbitrum)])
arr.append([BZX, BZX.replaceContract.encode_input(loanMaintenance_2)])
arr.append([BZX, BZX.replaceContract.encode_input(loanOpenings)])
arr.append([BZX, BZX.replaceContract.encode_input(loanClosings_Arbitrum)])
arr.append([BZX, BZX.replaceContract.encode_input(loanSettings)])
arr.append([BZX, BZX.replaceContract.encode_input(swapsImpl)])
arr.append([BZX, BZX.replaceContract.encode_input(receiver)])

# remember deploy WETH
# loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WETH:
        print("setting weth")
        # iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
        arr.append([iTokenTemp, iTokenTemp.setTarget.encode_input(loanTokenLogicWeth)])
    else:
        # iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})
        arr.append([iTokenTemp, iTokenTemp.setTarget.encode_input(loanTokenLogicStandard)])


# ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
# pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})

# BZX.setTWAISettings(60, 10800, {"from": GUARDIAN_MULTISIG})
arr.append([BZX, BZX.setTWAISettings.encode_input(60, 10800)])
for l in list:
    # calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})
    arr.append([BZX,  BZX.setupLoanPoolTWAI.encode_input(l[0])])

data1 = MULTICALL3.tryAggregate.encode_input(True, arr)
safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, SafeOperation.DELEGATE_CALL.value, safe_nonce=safe.pending_nonce())

# helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})

# HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperProxy.abi)
# HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
# HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)
# Testing
iUSDC.mint("X", 1e6, {"from": "X"})














# EXECUTION LOG
# <ClefAccount '0x70FC4dFc27f243789d07134Be3CA31306fD2C6B6'>
# >>> tickMath = TickMathV1.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x17076b9402a4576e7d7de17d918e5d5065fb1a5b20fa0947849c1ff671e80e14
#   Gas price: 0.5 gwei   Gas limit: 8073048   Nonce: 16
#   TickMathV1.constructor confirmed   Block: 9854022   Gas used: 6652135 (82.40%)
#   TickMathV1 deployed at: 0x7FcB75eaB54D5cEA49cC026Ae7A36ec8F56d7616

# >>> loanMaintenance_Arbitrum = LoanMaintenance.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x499181a5266ba4577555750ce0e17f943a045cc959866f5ed106b3d80542d5bf
#   Gas price: 0.5 gwei   Gas limit: 78527628   Nonce: 17
#   LoanMaintenance.constructor confirmed   Block: 9854062   Gas used: 64878513 (82.62%)
#   LoanMaintenance deployed at: 0x4A3A06D264e6F3B67e0BAae96F2457d3C4e3Fadd

# >>> loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0xcd06fd233e1667bc64242be7bc823517c3b62661e00c370c37f7c580c95fdc41
#   Gas price: 0.5 gwei   Gas limit: 52020922   Nonce: 18
#   LoanMaintenance_2.constructor confirmed   Block: 9854101   Gas used: 42973322 (82.61%)
#   LoanMaintenance_2 deployed at: 0xd076bEc0c440780D63A9Ad5B1C3BBB890196Edec

# >>> loanOpenings = LoanOpenings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x6c5636480a590eeb27606ce757730b71d9fdac320d68caa94e98ca0c05355eec
#   Gas price: 0.5 gwei   Gas limit: 85482867   Nonce: 19
#   LoanOpenings.constructor confirmed   Block: 9854131   Gas used: 70626685 (82.62%)
#   LoanOpenings deployed at: 0xd2B48A5534Ca5b1Fd182A87645055f414e45eDd1

# >>> loanClosings_Arbitrum = LoanClosings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x82ac5c5ed4213d590b8ff0d9cfcb4978b09c87e236c8866537c86ee056bc36e3
#   Gas price: 0.5 gwei   Gas limit: 100687649   Nonce: 20
#   LoanClosings.constructor confirmed   Block: 9854172   Gas used: 83192748 (82.62%)
#   LoanClosings deployed at: 0x8C085F8f5a5650D282BAce3A134dC22a67Cf411B

# >>> loanSettings = LoanSettings.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x3b8150d8fe7379e99043e251c20daf2e85e1c013dfc8ee8eefbe3aa659acb2d7
#   Gas price: 0.5 gwei   Gas limit: 61081053   Nonce: 21
#   LoanSettings.constructor confirmed   Block: 9854209   Gas used: 50458320 (82.61%)
#   LoanSettings deployed at: 0xfd203e1988dD07f52abd0712CCEAC131285c862B

# >>> swapsImpl = SwapsExternal.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0xfe251750382c8494ee28966c81ff457a630f68b57658629cfcf37f0539077578
#   Gas price: 0.5 gwei   Gas limit: 58890442   Nonce: 22
#   SwapsExternal.constructor confirmed   Block: 9854238   Gas used: 48649273 (82.61%)
#   SwapsExternal deployed at: 0x6a558dD573E5B3D4DdC6224699a5b91F974f28E4

# >>> receiver = Receiver.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0xc847724252bef813d968aac53d555467aec3a5901a4fbd3a43c3a6e51d47c102
#   Gas price: 0.5 gwei   Gas limit: 21432583   Nonce: 23
#   Receiver.constructor confirmed   Block: 9854263   Gas used: 17689285 (82.53%)
#   Receiver deployed at: 0x962616e11212D3843564d714b6090ffFF2C8D1dF

# >>> loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x364fb9bd31c55f630751bbb22d0e387841a8806f8947b24415aa6777f87ee2f3
#   Gas price: 0.5 gwei   Gas limit: 80484427   Nonce: 24
#   LoanTokenLogicStandard.constructor confirmed   Block: 9854305   Gas used: 66445482 (82.56%)
#   LoanTokenLogicStandard deployed at: 0x3b04d6af3054639a29cbBFc979933539c9b549F7

# >>> loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0x744358c759e61a2ac9993d00b0a2a7d83364e0366b33fc0d2774b76b18e56267
#   Gas price: 0.5 gwei   Gas limit: 83371011   Nonce: 25
#   LoanTokenLogicWeth.constructor confirmed   Block: 9854330   Gas used: 68832489 (82.56%)
#   LoanTokenLogicWeth deployed at: 0x53e3eE4F026f9d0dC874daEE5aB54CE6A441c17e

# >>>
# >>> ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0xfb6fd297b863540272cdb97d231a2a681f541160e85e84d9c6d5267e69e962e4
#   Gas price: 0.5 gwei   Gas limit: 11731650   Nonce: 26
#   OOKIPriceFeed.constructor confirmed   Block: 9854382   Gas used: 9675866 (82.48%)
#   OOKIPriceFeed deployed at: 0xA8DCa6006921bE2993AB41FA41A1634Dc20070Dd

# >>> helperImpl = HelperImpl.deploy({"from": deployer, "gas_price": Wei("0.5 gwei")})
# Transaction sent: 0xbf1edc6ae4e3fd0b8eac1d9bedd40b850413e1665287d3cab79d2575b1484dc6
#   Gas price: 0.5 gwei   Gas limit: 30226406   Nonce: 27
#   File "<console>", line 1, in <module>
#   File "brownie/network/contract.py", line 532, in __call__
#     return tx["from"].deploy(
#   File "brownie/network/account.py", line 510, in deploy
#     receipt, exc = self._make_transaction(
#   File "brownie/network/account.py", line 776, in _make_transaction
#     receipt = self._await_confirmation(receipt, required_confs, gas_strategy, gas_iter)
#   File "brownie/network/account.py", line 835, in _await_confirmation
#     raise TransactionError(f"Tx dropped without known replacement: {receipt.txid}")
# TransactionError: Tx dropped without known replacement: 0xbf1edc6ae4e3fd0b8eac1d9bedd40b850413e1665287d3cab79d2575b1484dc6
# >>> "0x04f5088268fa1bf8a0fa20dbf5b538d70d6ef708"
# '0x04f5088268fa1bf8a0fa20dbf5b538d70d6ef708'

# print results
# >>> loanMaintenance_Arbitrum
# <LoanMaintenance Contract '0x4A3A06D264e6F3B67e0BAae96F2457d3C4e3Fadd'>
# >>> loanMaintenance_2
# <LoanMaintenance_2 Contract '0xd076bEc0c440780D63A9Ad5B1C3BBB890196Edec'>
# >>> loanOpenings
# <Transaction '0x6c5636480a590eeb27606ce757730b71d9fdac320d68caa94e98ca0c05355eec'>
# >>> loanClosings_Arbitrum
# <LoanClosings Contract '0x8C085F8f5a5650D282BAce3A134dC22a67Cf411B'>
# >>> loanSettings
# <LoanSettings Contract '0xfd203e1988dD07f52abd0712CCEAC131285c862B'>
# >>> swapsImpl
# <SwapsExternal Contract '0x6a558dD573E5B3D4DdC6224699a5b91F974f28E4'>
# >>> receiver
# <Receiver Contract '0x962616e11212D3843564d714b6090ffFF2C8D1dF'>
# >>> loanTokenLogicStandard
# <LoanTokenLogicStandard Contract '0x3b04d6af3054639a29cbBFc979933539c9b549F7'>
# >>> loanTokenLogicWeth
# <LoanTokenLogicWeth Contract '0x53e3eE4F026f9d0dC874daEE5aB54CE6A441c17e'>
# >>> ookiPriceFeed
# <OOKIPriceFeed Contract '0xA8DCa6006921bE2993AB41FA41A1634Dc20070Dd'>
# >>> helperImpl
#   File "<console>", line 1, in <module>
# NameError: name 'helperImpl' is not defined
# >>> tickMath
# <TickMathV1 Contract '0x7FcB75eaB54D5cEA49cC026Ae7A36ec8F56d7616'>