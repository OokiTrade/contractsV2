#!/usr/bin/python3

import pytest

from brownie import *


# @pytest.fixture(scope="module", autouse=True)
# def mintCoordinator(accounts, MintCoordinator_Polygon, masterChef, govToken):
#     newMintCoordinator = accounts[0].deploy(MintCoordinator_Polygon);
#     newMintCoordinator.addMinter(masterChef)
#     newMintCoordinator.transferOwnership(masterChef)
#     masterChef.setMintCoordinator(newMintCoordinator, {'from': '0xB7F72028D9b502Dc871C444363a7aC5A52546608'})
#
#     govToken.transferOwnership(newMintCoordinator, {'from': govToken.owner()})
#     return newMintCoordinator

# @pytest.fixture(scope="module", autouse=True)
# def masterChef(accounts, MasterChef_Polygon, Proxy):
#     masterChefProxy = Contract.from_abi("masterChefProxy", address="0xd39Ff512C3e55373a30E94BB1398651420Ae1D43", abi=Proxy.abi)
#     masterChefImpl = MasterChef_Polygon.deploy({'from': masterChefProxy.owner()})
#     masterChefProxy.replaceImplementation(masterChefImpl, {'from': masterChefProxy.owner()})
#     masterChef = Contract.from_abi("masterChef", address=masterChefProxy, abi=MasterChef_Polygon.abi)
#
#
#     return masterChef

def testFarming_limit_minting(accounts, masterChef, mintCoordinator, govToken, MasterChef_Polygon):

    totalSupply = mintCoordinator.totalMinted()
    maxSupply = mintCoordinator.MAX_MINTED()  # 250 m
    # below deposit to trigger first mint to set totalMint in coordinator
    masterChef.deposit(0, 0 , {'from': accounts[0]})
    mintCoordinator.mint(accounts[0], maxSupply - totalSupply, {'from': masterChef})

    masterChef.deposit(0, 0 , {'from': accounts[0]})

    masterChef.deposit(0, 0 , {'from': accounts[0]})
    masterChef.deposit(0, 0 , {'from': accounts[0]})

    assert mintCoordinator.totalMinted() - mintCoordinator.MAX_MINTED() == 0 # no more minting
    assert masterChef.poolInfo(0)[1] == 0 # pool disabled
    govBalanceBefore = govToken.balanceOf(accounts[0]);
    mintCoordinator.mint(accounts[0], 1e6*1e18, {'from': masterChef})
    assert govToken.balanceOf(accounts[0]) - govBalanceBefore == 0


    