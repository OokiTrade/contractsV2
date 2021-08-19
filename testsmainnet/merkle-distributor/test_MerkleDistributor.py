#!/usr/bin/python3

import pytest
from brownie import network, Contract, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BAL(accounts, TestToken):
    return Contract.from_abi("BAL", address="0xba100000625a3754423978a60c9317c58a424e3D", abi=TestToken.abi)
 
@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    return Contract.from_abi("staking", address=stakingAddress,abi=StakingV1_1.abi)

@pytest.fixture(scope="module")
def MERKLEDISTRIBUITOR(accounts, LoanTokenLogicStandard, MerkleDistributor, BAL, STAKING):
    BAL.transfer(accounts[0], 3000*1e18, {'from': BAL})
    
    merkle = accounts[0].deploy(MerkleDistributor)
    BAL.approve(merkle, 3000*1e18, {'from': accounts[0]})
    merkleRootProof = "0x6f81aca6d06c49a679da8fbb05392b8cb27fa25c5e69a92f50c39fb5adacef59" # this is from merkleproof.json
    merkle.createAirdrop(BAL, merkleRootProof, merkle, 3000*1e18)
    merkle.setApproval(BAL, merkle, 2**256-1)
    return merkle


def testMerkleDistributor(requireMainnetFork, MERKLEDISTRIBUITOR, accounts, BAL, STAKING):
    assert MERKLEDISTRIBUITOR.airdropCount() == 1

    claimer = "0x00364d17C57868380Ef4F4effe8caf74d757742D"
    balanceBefore = BAL.balanceOf(claimer)
    index = 0
    amount =  "0x13574aeae8fe7200"
    proof = [
                "0x0c15f451d497c08a5edc3450c03a61153d71814ae5117554a8c1ffa97cc92e5a",
                "0xde828f013d44df2e723bac644c06441c19863a0ce936fa109491b1639d84155e",
                "0x63d85ffb797d6a5b62d50a5a80a472f6a17bc2d73cf10bcdc619ba6c6ce2146f",
                "0x6fa3a1461cc5c14e0f9a292881ce3cd3a36932b4537d30758bb00b4344390e4a",
                "0x608be47c94585ddbb41b1b562f415de2cf72a1e393cf9719a95cb36c9d68c48c",
                "0xde49da64f96eed7bf3f041bb7a81629c3f1fcbaf68449094358190c6232b0ff5"
            ]


    MERKLEDISTRIBUITOR.claim(0, index, claimer, amount, proof, {'from': claimer})
    balanceAfter = BAL.balanceOf(claimer)

    # this `amount` comes from output.json for this address
    expectedAmount = int(amount, 16)
    assert  expectedAmount == balanceAfter - balanceBefore


    with reverts("MerkleDistributor: Drop already claimed."):
        MERKLEDISTRIBUITOR.claim(0, index, claimer, amount, proof, {'from': claimer})
    assert False
