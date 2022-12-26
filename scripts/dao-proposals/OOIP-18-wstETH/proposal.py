from brownie import *

exec(open("./scripts/env/set-eth.py").read())

description = "OOIP-18-wstETH"

wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
NULL = "0x0000000000000000000000000000000000000000"

targets = []
values = []
calldatas = []

targets.append(BZX.address)
calldatas.append(BZX.setSupportedTokens.encode_input([WETH, wstETH],[True, True], True))
stETH = [BZX.generateLoanParamId(WETH, wstETH,True),True,NULL,WETH,wstETH,10e18,7e18,0]
stETH1 = [BZX.generateLoanParamId(WETH, wstETH,False),True,NULL,WETH,wstETH,10e18,7e18,1]

targets.append(BZX.address)
calldatas.append(BZX.modifyLoanParams.encode_input([stETH,stETH1]))
t = Receiver.deploy({"from":accounts[0]})
targets.append(BZX.address)
calldatas.append(BZX.replaceContract.encode_input(t))
values = [0] * len(targets)  # empty array
signatures = [""] * len(targets)  # empty signatures array


# Make proposal
call = DAO.propose(targets, values, signatures, calldatas, description, {'from': TEAM_VOTING_MULTISIG, "required_confs": 1})
print("call", call)