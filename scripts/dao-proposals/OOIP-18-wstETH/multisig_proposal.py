# exec(open("./scripts/deployment/polygon/deploy_price_feed.py").read())
exec(open("./scripts/env/set-eth.py").read())

# deployer = accounts[0]
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
from gnosis.safe import SafeOperation
from brownie import *
wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"

tx_list = []

wstETH_swap = SwapsImplstETH_ETH.deploy({"from":accounts[0]})

tx_list.append([BZX.swapsImpl(),Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).setDexID.encode_input(wstETH_swap.address)])

for tx in tx_list:
    sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.CALL.value, safe_nonce=safe.pending_nonce())
    safe.sign_with_frame(sTxn)
    safe.post_transaction(sTxn)