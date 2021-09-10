#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts
import json

@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BAL(accounts, TestToken):
    return Contract.from_abi("BAL", address="0xba100000625a3754423978a60c9317c58a424e3D", abi=TestToken.abi)

@pytest.fixture(scope="module")
def MERKLEDISTRIBUITOR(accounts, LoanTokenLogicStandard, MerkleDistributor, BAL):
    amount = 674965755171273444902
    BAL.transfer(accounts[0], amount, {'from': "0xF977814e90dA44bFA03b6295A0616a897441aceC"})
    
    merkle = accounts[0].deploy(MerkleDistributor)
    
    BAL.approve(merkle, amount, {'from': accounts[0]})
    merkleRootProof = "0x6ad0e1656269711e7dd825a7151218d39ae3cc20e7909eaf968dd4dbadcdcaa3" # this is from merkleproof.json
    merkle.createAirdrop(BAL, merkleRootProof, merkle, amount)
    return merkle


def testMerkleDistributorAllAccounts(requireMainnetFork, MERKLEDISTRIBUITOR, accounts, BAL):
    
    with open('./scripts/merkle-distributor/merkleproof.json', 'r') as myfile:
        data=myfile.read()
    merkleproof = json.loads(data)

    for proof in merkleproof['claims']:
        
        claimer = proof
        balanceBefore = BAL.balanceOf(claimer)
        index = merkleproof['claims'][proof]['index']
        amount = merkleproof['claims'][proof]['amount']
        proof = merkleproof['claims'][proof]['proof']
        
        print('index', index)
        MERKLEDISTRIBUITOR.claim(0, index, claimer, amount, proof, {'from': claimer})

        balanceAfter = BAL.balanceOf(claimer)

        expectedAmount = int(amount, 16)
        assert  expectedAmount == balanceAfter - balanceBefore


    assert BAL.balanceOf(MERKLEDISTRIBUITOR) < 1e5 # some lefties due to math calcs
    assert True


    # below info come from merkleproof.json
    claimer = "0x00364d17C57868380Ef4F4effe8caf74d757742D"
    balanceBefore = BAL.balanceOf(claimer)
    index = 0
    amount =  "0x0d0df3f688014700"
    proof = [
                "0x2b087ef16719779ba9ac65078dfef412d6373efc858e443437c04a3c57b43cce",
                "0xac935e2e9d08073f84155f3d5e7e5326eeaccc7fcc136ce5fc2cd1a1275281ef",
                "0x4c40b206b11535480d16400ef1e8a81ac947d4146ffb787bfbb4e07395fa8f38",
                "0x7c501969c97a1397d4460cf31c062c32f5532b896b42d35ef25b363362c510fd",
                "0x9fb5e133cefc22b338a7b1667a1c454c9b46f34a2a82cd0a8733aa9ae6f3f26f",
                "0xe0b3f19a397359f80c5f62fae85edd74133439c5a5fbf1350f33a2be99448a6d"
            ]

    with reverts("MerkleDistributor: Drop already claimed."):
        MERKLEDISTRIBUITOR.claim(0, index, claimer, amount, proof, {'from': claimer})