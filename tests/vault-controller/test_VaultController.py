#!/usr/bin/python3

import pytest



@pytest.fixture(scope="module", autouse=True)
def vault(LoanSettings, accounts, bzx, VaultController):
    return accounts[0].deploy(VaultController)

def test_vaultTransfer(Constants, bzx, vault, DAI, accounts):
    print("vault", vault)
    tx = vault.vaultTransfer(DAI, accounts[1], accounts[2], "1 ether")
    print("tx", tx.info())
    assert False

# def test_vaultApprove(Constants, bzx, vaultController, DAI):
#     assert False

