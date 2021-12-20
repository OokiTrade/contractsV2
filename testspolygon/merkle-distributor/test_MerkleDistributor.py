#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts
import json

@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())

@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    return Contract.from_abi("BZRX", address="0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2", abi=TestToken.abi)

@pytest.fixture(scope="module")
def P125(accounts, TestToken):
    return Contract.from_abi("P125", address="0x83000597e8420aD7e9EDD410b2883Df1b83823cF", abi=TestToken.abi)

@pytest.fixture(scope="module")
def MERKLEDISTRIBUITOR(accounts, MerkleDistributor, P125, BZRX, Proxy_0_8):
    multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'

    # merkleImpl = MerkleDistributor.deploy({'from': accounts[0]})
    # merkleProxy = Proxy_0_8.deploy(merkleImpl, {'from': accounts[0]})

    #0x59a6579C039F84A758665Ca416394BdF6A05985d
    merkle = Contract.from_abi("P125", address="0x59a6579C039F84A758665Ca416394BdF6A05985d", abi=MerkleDistributor.abi)



    merkleRootProof = "0x6ad0e1656269711e7dd825a7151218d39ae3cc20e7909eaf968dd4dbadcdcaa3" # this is from merkleproof.json
    merkle.createAirdrop(P125, merkleRootProof, multisign, 674965755171273444902, {'from': merkle.owner()})
    merkle.createAirdrop(P125, merkleRootProof, multisign, 674965755171273444902, {'from': merkle.owner()})

    merkle.transferOwnership(multisign, {'from': merkle.owner()})
    P125.approve(merkle, 2**256-1, {'from': multisign})
    BZRX.approve(merkle, 2**256-1, {'from': multisign})

    return merkle



def _merkleDistributor(airdropIndex, MERKLEDISTRIBUITOR, accounts, P125):

    with open('./scripts/merkle-distributor/merkleproof.json', 'r') as myfile:
        data=myfile.read()
    merkleproof = json.loads(data)

    for proof in merkleproof['claims']:
        claimer = proof
        balanceBefore = P125.balanceOf(claimer)
        index = merkleproof['claims'][proof]['index']
        amount = merkleproof['claims'][proof]['amount']
        proof = merkleproof['claims'][proof]['proof']

        MERKLEDISTRIBUITOR.claim(airdropIndex, index, claimer, amount, proof, {'from': claimer})

        balanceAfter = P125.balanceOf(claimer)

        expectedAmount = int(amount, 16)
        assert  expectedAmount == balanceAfter - balanceBefore

    assert True


    # below info come from merkleproof.json
    claimer = "0x00364d17C57868380Ef4F4effe8caf74d757742D"
    balanceBefore = P125.balanceOf(claimer)
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
    with reverts("MerkleDistributor: account != sender"):
        MERKLEDISTRIBUITOR.claim(1, index, claimer, amount, proof, {'from': accounts[1]})
    with reverts("MerkleDistributor: Drop already claimed."):
        MERKLEDISTRIBUITOR.claim(airdropIndex, index, claimer, amount, proof, {'from': claimer})



def testMerkleDistributor_0(requireFork, MERKLEDISTRIBUITOR, accounts, P125):
    _merkleDistributor(0, MERKLEDISTRIBUITOR,accounts,P125)
    assert P125.balanceOf(MERKLEDISTRIBUITOR) < 674965755171273444902 + 1e5 # some lefties due to math calcs

def testMerkleDistributor_1(requireFork, MERKLEDISTRIBUITOR, accounts, P125):
    #Checking aminCliam
    claimer = "0x038d65443DA94befdFb9E59A3dE22193De018998"
    balanceBeforeA = P125.balanceOf(claimer)
    balanceBeforeB = P125.balanceOf(accounts[1])
    index = 1
    amount =  "0x69054add6769fc00"
    proof = [
        "0x3767fb51306bcade9da4808404d99b34e4ef36000c3a07ea0364ec3727be7d1c",
        "0xef197e7822e91ab3700c989926387b05d4687a1f05a7fb1f6e2daf0fadd273b0",
        "0x8fabe8bc047cf9f2d7f423587a1accc146d0b6da8e124041f52c778f0f7ce302",
        "0x48321d094c9640c03ccdfcb40f8eed55d1828ae60196ac79107a0c38a089ae8b",
        "0x9d73cc7c163e3f3760f2ba21d176cae9f9a3cfca4cbbaf13f9d6b7ec4c7ad626",
        "0xe0b3f19a397359f80c5f62fae85edd74133439c5a5fbf1350f33a2be99448a6d"
    ]
    with reverts("Ownable: caller is not the owner"):
        MERKLEDISTRIBUITOR.adminClaim(1, index, claimer, amount, accounts[1], proof, {'from': claimer})

    tx = MERKLEDISTRIBUITOR.adminClaim(1, index, claimer, amount, accounts[1], proof, {'from': MERKLEDISTRIBUITOR.owner()})

    assert balanceBeforeA == P125.balanceOf(claimer)
    assert balanceBeforeB < P125.balanceOf(accounts[1])


def testMerkleDistributor_2(requireFork, MERKLEDISTRIBUITOR, accounts, P125):
    amount = 100e18
    balanceBeforeA = P125.balanceOf(accounts[1])
    balanceBeforeB = P125.balanceOf(accounts[2])
    with reverts("Ownable: caller is not the owner"):
        MERKLEDISTRIBUITOR.directClaim(0, accounts[2], amount, {'from': accounts[1]})

    tx = MERKLEDISTRIBUITOR.directClaim(1, accounts[2], amount, {'from': MERKLEDISTRIBUITOR.owner()})
    assert balanceBeforeA == P125.balanceOf(accounts[1])
    assert balanceBeforeB < P125.balanceOf(accounts[2])
