exec(open("./scripts/env/set_arbitrum.py").read())

# TODO check pausable guardian for storage conflicts
# 1. Deploy double proxy admin
# 2. Deploy implementation ltls
# 3. Deploy double proxy - once. the factory will deploy second
# 4. Deploy CUI
# 5. Deploy  ITokenFactory

ltdpa = LoanTokenDoubleProxyAdmin.deploy({"from": accounts[0]}) # TODO owned by TIMELOCK in the future
arbCaller = "0x01207468F48822f8535BC96D1Cf18EddDE4A2392"
bzxcontract = "0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB"
wethtoken =  "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
ltls = LoanTokenLogicStandard.deploy(arbCaller, bzxcontract, wethtoken, {"from": accounts[0]})


ltdp_middle = LoanTokenDoubleProxy.deploy(ltls, ltdpa, b"", {"from": accounts[0]})
ltdp_top= LoanTokenDoubleProxy.deploy(ltdp_middle, ltdpa, b"", {"from": accounts[0]})
# iTokenMiddle = interface.IToken(ltdp_middle)
# iTokenTop = interface.IToken(ltdp_top)

# # TODO CUI deploy
# ltf = LoanTokenFactory.deploy(bzxcontract, GUARDIAN_MULTISIG, GUARDIAN_MULTISIG, ltdp_middle, ltdpa, CUI, {"from": accounts[0]})


# tt = TestToken.deploy("a", "b", 18, 1e6*1e18, {"from": accounts[0]})
# ltf.addNewToken(tt, "", {"from": accounts[0]})

# a = "0x4c150dCd7775c48Ff5dbDe6305C319a1CF9D9773"