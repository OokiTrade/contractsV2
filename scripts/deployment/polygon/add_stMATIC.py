from brownie import *

exec(open("./scripts/env/set-matic.py").read())

STMATIC_FEED = Contract.from_abi("","0xF47a71F71B2b9A85c8d49c747e5C002e77245302",PriceFeedstMATIC.abi)
STMATIC = "0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4"
MATIC = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
NULL = "0x0000000000000000000000000000000000000000"
calls = []
tokens = []
for l in list:
    tokens.append(l[1])
calls.append([PRICE_FEED.address,False,PRICE_FEED.setPriceFeed.encode_input([STMATIC],[STMATIC_FEED.address])])
#add balancer swap impl to dex records
calls.append([BZX.swapsImpl(),False,Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).setDexID.encode_input("0x5281d5BbA9162B41320A2fc760F67B9e02fFd793")])
#set the tokens to be supported
calls.append([BZX.address,False,BZX.setSupportedTokens.encode_input([STMATIC],[True], True)])
#calls.append([BZX.address,False,BZX.setApprovals.encode_input(tokens,[Contract.from_abi("",BZX.swapsImpl(),DexRecords.abi).getDexCount()])])
#modify params for stMATIC/MATIC to be 10% initial and 7% maintenance
STMATIC_PARAMS = [BZX.generateLoanParamId(MATIC, STMATIC,True),True,NULL,MATIC,STMATIC,10e18,7e18,0]
STMATIC_PARAM = [BZX.generateLoanParamId(MATIC, STMATIC,False),True,NULL,MATIC,STMATIC,10e18,7e18,1]

calls.append([BZX.address,False,BZX.modifyLoanParams.encode_input([STMATIC_PARAMS,STMATIC_PARAM])])

print(interface.IMulticall3("0xcA11bde05977b3631167028862bE2a173976CA11").aggregate3.encode_input(calls))