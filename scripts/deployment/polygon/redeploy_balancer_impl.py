# exec(open("./scripts/deployment/polygon/deploy_price_feed.py").read())
exec(open("./scripts/env/set-matic.py").read())
deployer = accounts[0]
from brownie import *
from ape_safe import ApeSafe
safe = ApeSafe(GUARDIAN_MULTISIG)
from gnosis.safe import SafeOperation

bal = SwapsImplBalancer_POLYGON.deploy({"from":deployer}, publish_source=True)

tx_list = []
DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(),DexRecords.abi)
tx_list.append([DEX_RECORDS,DEX_RECORDS.setDexID.encode_input(3,bal)])

for tx in tx_list:
    sTxn = safe.build_multisig_tx(tx[0].address, 0, tx[1], SafeOperation.CALL.value, safe_nonce=safe.pending_nonce())
    safe.sign_with_frame(sTxn)
    safe.post_transaction(sTxn)