#!/usr/bin/python3

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb


acct = accounts[0]
bzx = acct.deploy(bZxProtocol)

bzx.replaceContract(acct.deploy(ProtocolSettings).address)
bzx.replaceContract(acct.deploy(LoanSettings).address)
bzx.replaceContract(acct.deploy(LoanMaintenance).address)
bzx.replaceContract(acct.deploy(LoanOpenings).address)
bzx.replaceContract(acct.deploy(LoanClosings).address)
bzx.replaceContract(acct.deploy(SwapsExternal).address)




# TODO
bzx.setPriceFeedContract(
    priceFeeds.address # priceFeeds
)

bzx.setSwapsImplContract(
    swapsImpl.address # swapsImpl
)


