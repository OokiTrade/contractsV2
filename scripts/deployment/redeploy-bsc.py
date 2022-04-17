exec(open("./scripts/env/set-bsc.py").read())
deployer = accounts[2]
from gnosis.safe import Safe, SafeOperation
from ape_safe import ApeSafe

safe = ApeSafe(GUARDIAN_MULTISIG)

# LINK.transfer(accounts[0], 1000e18, {'from': "0x21d45650db732ce5df77685d6021d7d5d1da807f"})
# LINK.approve(iLINK, 2**256-1, {'from':accounts[0]})
# iLINK.mint(accounts[0], 1e18, {"from": accounts[0]})


tickMath = TickMathV1.deploy({"from": deployer})
loanMaintenance = LoanMaintenance.deploy({"from": deployer})
loanMaintenance_2 = LoanMaintenance_2.deploy({"from": deployer})
loanOpenings = LoanOpenings.deploy({"from": deployer})
loanClosings = LoanClosings.deploy({"from": deployer})
loanSettings = LoanSettings.deploy({"from": deployer})
swapsImpl = SwapsExternal.deploy({"from": deployer})

BZX.replaceContract(loanMaintenance, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanMaintenance_2, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanOpenings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanClosings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(loanSettings, {"from": GUARDIAN_MULTISIG})
BZX.replaceContract(swapsImpl, {"from": GUARDIAN_MULTISIG})

# # remember deploy ETH
loanTokenLogicStandard = LoanTokenLogicStandard.deploy({"from": deployer})
loanTokenLogicWeth = LoanTokenLogicWeth.deploy({"from": deployer})

for l in list:
    iTokenTemp = Contract.from_abi("iTokenTemp", l[0], LoanToken.abi)
    if l[1] == WBNB:
        print("setting WBNB")
        iTokenTemp.setTarget(loanTokenLogicWeth, {"from": GUARDIAN_MULTISIG})
    else:
        iTokenTemp.setTarget(loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})


# # ookiPriceFeed = OOKIPriceFeed.deploy({"from": deployer})
# pricefeeds = Contract.from_abi('priceFeeds',BZX.priceFeeds(),PriceFeeds.abi)
# pricefeeds.setPriceFeed([OOKI],[ookiPriceFeed], {"from": GUARDIAN_MULTISIG})

BZX.setTWAISettings(60, 10800, {"from": GUARDIAN_MULTISIG})

for l in list:
    calldata = BZX.setupLoanPoolTWAI(l[0], {"from": GUARDIAN_MULTISIG})


# data1 = MULTICALL3.tryAggregate.encode_input(True, arr)
# safeTx = safe.build_multisig_tx(MULTICALL3.address, 0, data1, SafeOperation.DELEGATE_CALL.value, safe_nonce=safe.pending_nonce())

helperImpl = HelperImpl.deploy({"from": deployer})
HELPER = Contract.from_abi("HELPER", HELPER, HelperProxy.abi)
HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
HELPER = Contract.from_abi("HELPER", HELPER, HelperImpl.abi)

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
