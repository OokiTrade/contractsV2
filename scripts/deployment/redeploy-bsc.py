exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[2]
from gnosis.safe import Safe, SafeOperation
from ape_safe import ApeSafe

safe = ApeSafe(GUARDIAN_MULTISIG)

# tickMath = TickMathV1.deploy({"from": deployer})
# loanMaintenance = LoanMaintenance.deploy({"from": deployer})
# loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
# loanOpenings = LoanOpenings.deploy({"from": deployer})
# loanClosings = LoanClosings.deploy({"from": deployer})
# loanSettings = LoanSettings.deploy({"from": deployer})
# swapsImpl = SwapsExternal.deploy({"from": deployer})

tickMath = Contract.from_abi("TickMathV1", "0xD36913f0225E64C4689b5D6144CeF952d1ad23dA", TickMathV1.abi)
loanMaintenance = Contract.from_abi("LoanMaintenance", "0x49743dA77Ff019424E2e153A0712eD87fFDB74Eb", LoanMaintenance.abi)
loanMaintenance_2 = Contract.from_abi("LoanMaintenance_2", "0xeCb076B674d585521087B3162A4F2bc76534Ac54", LoanMaintenance_2.abi)
loanOpenings = Contract.from_abi("LoanOpenings", "0x0DAE2558B8438c5089112F730aa319a2727E9912", LoanOpenings.abi)
loanClosings = Contract.from_abi("LoanClosings", "0x1CFE42F0a4ff79CCbC131E6EBDFab01D376D00c3", LoanClosings.abi)
loanSettings = Contract.from_abi("LoanSettings", "0x831dFCa1fB4C35bB68F4B5D94Ce81a2072E2dFEe", LoanSettings.abi)
swapsImpl = Contract.from_abi("SwapsExternal", "0xf7Eb8B08C8860d494D8d8FB6529C46Df599987BB", SwapsExternal.abi)


loanTokenLogicStandard = Contract.from_abi("LoanTokenLogicStandard", "0xE42f4147Ce8bf8D436554feE950ef11DBCeB90f7", LoanTokenLogicStandard.abi)
loanTokenLogicWeth = Contract.from_abi("LoanTokenLogicWeth", "0x174AFF1bE8da9710A1eC59c1c1b73c9bF6c60b8e", LoanTokenLogicWeth.abi)

helperImpl = Contract.from_abi("HelperImpl", "0x7FcB75eaB54D5cEA49cC026Ae7A36ec8F56d7616", HelperImpl.abi)

# BZX.replaceContract(loanMaintenance, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanClosings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
# BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})
arr = []
arr.append([BZX, BZX.replaceContract.encode_input(loanMaintenance)])
arr.append([BZX, BZX.replaceContract.encode_input(loanMaintenance_2)])
arr.append([BZX, BZX.replaceContract.encode_input(loanOpenings)])
arr.append([BZX, BZX.replaceContract.encode_input(loanClosings)])
arr.append([BZX, BZX.replaceContract.encode_input(loanSettings)])
arr.append([BZX, BZX.replaceContract.encode_input(swapsImpl)])
# # # remember deploy ETH
# loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
# loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WBNB:
        print("setting WBNB")
        # iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
        arr.append([iTokenTemp, iTokenTemp.setTarget.encode_input(loanTokenLogicWeth)])
    else:
        # iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})
        arr.append([iTokenTemp, iTokenTemp.setTarget.encode_input(loanTokenLogicStandard)])


# # ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer})
# pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
# pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})

# BZX.setTWAISettings(60, 10800, {"from": GUARDIAN_MULTISIG})
arr.append([BZX, BZX.setTWAISettings.encode_input(60, 10800)])

for l in list:
    # calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})
    arr.append([BZX,  BZX.setupLoanPoolTWAI.encode_input(l[0])])


# data1 = MULTICALL3.tryAggregate.encode_input(True, arr)
# safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, SafeOperation.DELEGATE_CALL.value, safe_nonce=safe.pending_nonce())

# # helperImpl = HelperImpl.deploy({"from": deployer})
# HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
# HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
# HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

# Testing
USDT.transfer(accounts[0] ,10000e18, {"from": "0x9aa83081aa06af7208dcc7a4cb72c94d057d2cda"})
USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
iUSDT.mint(accounts[0], 1000e18, {"from": accounts[0]})
iUSDT.burn(accounts[0], 1e18, {"from": accounts[0]})

iBNB.mintWithEther(accounts[0], {"from": accounts[0], "value": Wei("10 ether")})

print("Borrow WBNB, collateral ETH")
ETH.transfer(accounts[0], 100e18, {'from': "0xf977814e90da44bfa03b6295a0616a897441acec"})
ETH.approve(iBNB, 2**256-1, {'from':accounts[0]})
iBNB.borrow("", 0.1e18, 7884000, 1e18, ETH, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow WBNB, collateral LINK")
LINK.transfer(accounts[0], 1000e18, {'from': "0x21d45650db732ce5df77685d6021d7d5d1da807f"})
LINK.approve(iBNB, 2**256-1, {'from':accounts[0]})
iBNB.borrow("", 1e18, 7884000, 100e18, LINK, accounts[0], accounts[0], b"", {'from': accounts[0]})

print("Borrow LINK, collateral WBNB")
WBNB.approve(iLINK, 2**256-1, {'from':accounts[0]})
iLINK.borrow("", 1e18, 7884000, 1e18, WBNB, accounts[0], accounts[0], b"", {'from': accounts[0], "value": 1e18})

trades = BZX.getUserLoans(accounts[0], 0,10, 0,0,0)
LINK.approve(BZX, 2**256-1, {'from': accounts[0]})
BZX.closeWithDeposit(trades[0][0],accounts[0],trades[0][4],{'from':accounts[0]})

print("Trade WBNB/ETH")
iETH.marginTrade(0, 2e18, 0, 0.04e18, "0x0000000000000000000000000000000000000000", accounts[0], b'',{'from': accounts[0],  'value': Wei(0.04e18)})
print("Trade WBNB/ETH")
iBNB.marginTrade(0, 2e18, 0, 0.04e18, ETH, accounts[0], b'',{'from': accounts[0]})
print("Trade WBNB/LINK")
iBNB.marginTrade(0, 2e18, 0, 1e18, LINK, accounts[0], b'',{'from': accounts[0]})
print("Trade WBNB/USDT")
USDT.approve(iBNB, 2**256-1, {"from": accounts[0]})
iBNB.marginTrade(0, 2e18, 0, 1e6, USDT, accounts[0], b'',{'from': accounts[0]})
print("Trade USDT/WBNB")
# LINK.approve(iUSDT, 2**256-1, {'from':accounts[0]})
# iUSDT.marginTrade(0, 2e18, 0, 100e18, LINK, accounts[0], b'',{'from': accounts[0]})
WBNB.approve(iUSDT, 2**256-1, {'from':accounts[0]})
iUSDT.marginTrade(0, 2e18, 0, 1e18, WBNB, accounts[0], b'',{'from': accounts[0], "value": 1e18})



# deploy log

# >>> tickMath = TickMathV1.deploy({"from": deployer})
# Transaction sent: 0x6aa2aa33535952663544f1fb38dac5455d8f50e0e8e4e703820a251fdc8558e8
#   Gas price: 5.0 gwei   Gas limit: 501806   Nonce: 7
#   TickMathV1.constructor confirmed   Block: 17048773   Gas used: 456188 (90.91%)
#   TickMathV1 deployed at: 0xD36913f0225E64C4689b5D6144CeF952d1ad23dA
# >>> tickMath
# <Transaction '0x6aa2aa33535952663544f1fb38dac5455d8f50e0e8e4e703820a251fdc8558e8'>
# >>> tickMath
# <Transaction '0x6aa2aa33535952663544f1fb38dac5455d8f50e0e8e4e703820a251fdc8558e8'>
# >>> tickMath = Contract.from_abi("TickMathV1", "0xD36913f0225E64C4689b5D6144CeF952d1ad23dA", TickMathV1.abi)
# >>> tickMath
# <TickMathV1 Contract '0xD36913f0225E64C4689b5D6144CeF952d1ad23dA'>
# >>> loanMaintenance = LoanMaintenance.deploy({"from": deployer})
# >>> tickMath = TickMathV1.at("0xD36913f0225E64C4689b5D6144CeF952d1ad23dA")
# >>> tickMath
# <TickMathV1 Contract '0xD36913f0225E64C4689b5D6144CeF952d1ad23dA'>
# >>> loanMaintenance = LoanMaintenance.deploy({"from": deployer})
# Transaction sent: 0x61e9e563e453b08ae8cb316b20946bb8f95b570ce0e1b6149e153cf04187d25d
#   Gas price: 5.0 gwei   Gas limit: 4705233   Nonce: 8
#   LoanMaintenance.constructor confirmed   Block: 17048815   Gas used: 4277485 (90.91%)
#   LoanMaintenance deployed at: 0x49743dA77Ff019424E2e153A0712eD87fFDB74Eb

# >>> loanMaintenance
# <Transaction '0x61e9e563e453b08ae8cb316b20946bb8f95b570ce0e1b6149e153cf04187d25d'>
# >>> loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
# Transaction sent: 0x67679523c92e9951a00ba6a4bc658f5ba0c22ec2fdf64f5b7e72945086bb837d
#   Gas price: 5.0 gwei   Gas limit: 3167457   Nonce: 9
#   LoanMaintenance_2.constructor confirmed   Block: 17048832   Gas used: 2879507 (90.91%)
#   LoanMaintenance_2 deployed at: 0xeCb076B674d585521087B3162A4F2bc76534Ac54

# >>> loanOpenings = LoanOpenings.deploy({"from": deployer})
# Transaction sent: 0xa2fed999327caa48f154e1e42f5c05feb5982695ae899585e7862eb5455e817a
#   Gas price: 5.0 gwei   Gas limit: 5082778   Nonce: 10
#   LoanOpenings.constructor confirmed   Block: 17048840   Gas used: 4620708 (90.91%)
#   LoanOpenings deployed at: 0x0DAE2558B8438c5089112F730aa319a2727E9912

# >>> loanClosings = LoanClosings.deploy({"from": deployer})
# Transaction sent: 0x592f825ca7b38d9d7832b6d9a034a0691852803697141b7308a0b0bf8d6b0b20
#   Gas price: 5.0 gwei   Gas limit: 5962881   Nonce: 11
#   LoanClosings.constructor confirmed   Block: 17048846   Gas used: 5420801 (90.91%)
#   LoanClosings deployed at: 0x1CFE42F0a4ff79CCbC131E6EBDFab01D376D00c3

# >>> loanSettings = LoanSettings.deploy({"from": deployer})
# Transaction sent: 0x9b02f2e1658bdcf4540a60987ae2d5144cab1c657de275508b095e46e565b8ba
#   Gas price: 5.0 gwei   Gas limit: 3695447   Nonce: 12
#   LoanSettings.constructor confirmed   Block: 17048853   Gas used: 3359498 (90.91%)
#   LoanSettings deployed at: 0x831dFCa1fB4C35bB68F4B5D94Ce81a2072E2dFEe

# >>> swapsImpl = SwapsExternal.deploy({"from": deployer})
# Transaction sent: 0x92bc6838124cf5ec886a53285a6b0a10215677969e0f5cc7c8e23dbdfdd12642
#   Gas price: 5.0 gwei   Gas limit: 3549188   Nonce: 13
#   SwapsExternal.constructor confirmed   Block: 17048859   Gas used: 3226535 (90.91%)
#   SwapsExternal deployed at: 0xf7Eb8B08C8860d494D8d8FB6529C46Df599987BB

# >>> loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
# Transaction sent: 0xce3a67c8b87e245bd512fc411a00df9cd986b389fc208cefce9ec9a7dc5ab48d
#   Gas price: 5.0 gwei   Gas limit: 4681880   Nonce: 14
#   LoanTokenLogicStandard.constructor confirmed   Block: 17048865   Gas used: 4237055 (90.50%)
#   LoanTokenLogicStandard deployed at: 0xE42f4147Ce8bf8D436554feE950ef11DBCeB90f7

# >>> loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})
# Transaction sent: 0xd0205ee44f767af372405853da180113724da8a970b9053d6c9e93b03be6db6a
#   Gas price: 5.0 gwei   Gas limit: 4851928   Nonce: 15
#   LoanTokenLogicWeth.constructor confirmed   Block: 17048875   Gas used: 4391644 (90.51%)
#   LoanTokenLogicWeth deployed at: 0x174AFF1bE8da9710A1eC59c1c1b73c9bF6c60b8e

# >>> helperImpl = HelperImpl.deploy({"from": deployer})
# Transaction sent: 0x101d48698bea1b28fb698cdbee438225958e40fb12663bc740b7f2036fd2e03a
#   Gas price: 5.0 gwei   Gas limit: 1780175   Nonce: 16
#   HelperImpl.constructor confirmed   Block: 17048884   Gas used: 1618341 (90.91%)
#   HelperImpl deployed at: 0x7FcB75eaB54D5cEA49cC026Ae7A36ec8F56d7616
