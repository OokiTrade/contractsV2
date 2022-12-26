# exec(open("./scripts/deployment/polygon/deploy_price_feed.py").read())
exec(open("./scripts/env/set-eth.py").read())

# deployer = accounts[0]
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
from gnosis.safe import SafeOperation
from brownie import *
wstETH_FEED = PriceFeedwstETH.deploy({"from":accounts[0]}) #Contract.from_abi("","",PriceFeedwstETH.abi)
wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
PRICE_FEED = PriceFeeds.at("0x09Ef93750C5F33ab469851F022C1C42056a8BAda")

tx_list = []

tx_list.append([PRICE_FEED, PRICE_FEED.setPriceFeed.encode_input([wstETH],[wstETH_FEED.address])])

wstETH_swap = SwapsImplstETH_ETH.deploy({"from":accounts[0]})

tx_list.append([BZX.swapsImpl(),Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).setDexID.encode_input(wstETH_swap.address)])

for tx in tx_list:
    sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.CALL.value, safe_nonce=safe.pending_nonce())
    safe.sign_with_frame(sTxn)
    safe.post_transaction(sTxn)