# global functions
from ape_safe import ApeSafe
def createGnosisTx(safe:ApeSafe, target, calldata, index=0):
  to = target
  value = 0
  data = calldata
  operation = 0
  safe_nonce = index # TODO handle custom index in case of replace
  safeTx = safe.build_multisig_tx(to, value, data, operation, safe_nonce=safe_nonce)
  print(safeTx)
  # signature = safe.sign_with_frame(safeTx)
  # safe.post_transaction(safeTx)
  return safeTx
  # index = index + 1
  # safe.preview(safeTx)
  # assert False
