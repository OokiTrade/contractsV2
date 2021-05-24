#!/usr/bin/python3
import pytest
import brownie
from brownie import network, Contract, Wei, reverts
from brownie.network.contract import InterfaceContainer


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

@pytest.fixture(scope="module")
def iDAI(accounts, LoanTokenLogicStandard):
    # return Contract.from_abi("iDAI", address="0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0",  abi=LoanTokenLogicStandard.abi, owner=accounts[0])
    return loadContractFromAbi("0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", "iDAI", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def bzx(accounts, LoanTokenLogicStandard, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",  abi=interface.IBZx.abi, owner=accounts[0])
    # return Contract.from_explorer("0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f")


@pytest.fixture(scope="module")
def DAI(accounts, LoanTokenLogicStandard, TestToken):
    # return Contract.from_abi("DAI", address="0x6B175474E89094C44Da98b954EedeAC495271d0F",  abi=TestToken.abi, owner=accounts[0])
    return loadContractFromAbi("0x6b175474e89094c44da98b954eedeac495271d0f", "DAI", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def WETH(accounts, LoanTokenLogicStandard):
    # return Contract.from_abi("WETH", address="0x2956356cd2a2bf3202f771f50d3d14a367b48070",  abi=TestToken.abi, owner=accounts[0])
    return loadContractFromAbi("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH", LoanTokenLogicStandard.abi)


@pytest.fixture(scope="module")
def iETH(accounts, LoanTokenLogicStandard, LoanTokenLogicWeth):
    return Contract.from_abi("iETH", address="0xb983e01458529665007ff7e0cddecdb74b967eb6",  abi=LoanTokenLogicWeth.abi, owner=accounts[0])


def testMint5(requireMainnetFork, WETH, iETH, accounts, bzx):
    # this is unreachable
    assert True


def testMint6(requireMainnetFork, iETH, accounts):
    with reverts("6"):
        iETH.borrow(0, 0, 0, 0, iETH.loanTokenAddress(),
                    accounts[1], accounts[2], 0)


def testMint7(requireMainnetFork, iETH, accounts):
    with reverts("7"):
        iETH.borrow(0, 1, 0, 1, iETH.loanTokenAddress(),
                    accounts[1], accounts[2], 0, {'amount': 2})


def testMint8(requireMainnetFork, iETH, accounts):
    with reverts("8"):
        iETH.borrow(0, 1, 0, 0, iETH.loanTokenAddress(),
                    accounts[1], accounts[2], 0)


def testMint9(requireMainnetFork, iETH, accounts, Constants):
    with reverts("9"):
        iETH.borrow(0, 1, 0, 1, "0x0000000000000000000000000000000000000000",
                    accounts[2], accounts[2], 0)


def testMint10(requireMainnetFork, iETH, accounts):
    iETH.mintWithEther(
        accounts[2], {'from': accounts[1], 'amount':  Wei('0.1 ether')})
    with reverts("10"):
        iETH.borrow(0, 1, 0, 1, iETH.loanTokenAddress(),
                    accounts[1], accounts[2], 0)


def testMint11(requireMainnetFork, iETH, accounts):
    with reverts("11"):
        iETH.marginTrade(0, 0, 0, 0, iETH.loanTokenAddress(), accounts[1], 0)


def testMint11IfCase(requireMainnetFork, iETH, WETH, DAI, accounts):
    with reverts("11"):
        iETH.marginTrade(0, 0, 0, 0, WETH.address, accounts[1], 0)


def testMint12(requireMainnetFork, iETH, WETH, DAI, iDAI, accounts):
    with reverts("SafeMath: division by zero"):
        iDAI.marginTrade(0, 0, 0, 0, WETH.address,
                         accounts[1], 0, {'from': accounts[1]})
    with reverts("12"):
        iDAI.marginTrade(0, 1, 0, 0, WETH.address,
                         accounts[1], 0, {'from': accounts[1]})


def testMint13(requireMainnetFork, iETH, accounts):
    with reverts("13"):
        iETH.marginTrade(1, 0, 0, 0, accounts[1], iETH.loanTokenAddress(), 0, {
                         'from': accounts[2]})


def testMint14(requireMainnetFork, iETH, accounts):
    iETH.mintWithEther(
        accounts[2], {'from': accounts[1], 'amount':  Wei('0.1 ether')})
    with reverts("14"):
        iETH.transferFrom(accounts[1], accounts[2], Wei('1 ether'))


def testMint15(requireMainnetFork, iETH, accounts):
    iETH.mintWithEther(
        accounts[2], {'from': accounts[1], 'amount':  Wei('0.1 ether')})
    iETH.approve(accounts[1], Wei('10 ether'), {'from': accounts[1]})
    with reverts("15"):
        iETH.transferFrom(
            accounts[1], "0x0000000000000000000000000000000000000000", Wei('0.01 ether'), {'from': accounts[1]})


def testMint16(requireMainnetFork, iETH, accounts):
    iETH.mintWithEther(
        accounts[2], {'from': accounts[1], 'amount':  Wei('1 ether')})
    iETH.approve(accounts[1], Wei('10 ether'), {'from': accounts[1]})
    with reverts("16"):
        iETH.transferFrom(
            accounts[1], accounts[1], Wei('2 ether'), {'from': accounts[1]})


def testMint17(requireMainnetFork, iETH, accounts):
    with reverts("17"):
        iETH.mintWithEther(
            accounts[2], {'from': accounts[1], 'amount': 0})


def testMint18(requireMainnetFork, iETH, accounts):
    with reverts("18"):
        iETH.mint(accounts[1], Wei('1 ether'))


def testMint19(requireMainnetFork, iETH, accounts):
    with reverts("19"):
        iETH.burn(accounts[1], 0)


def testMint24(requireMainnetFork, iETH, DAI, accounts):
    iETH.mintWithEther(
        accounts[1], {'from': accounts[1], 'amount':  Wei('1 ether')})
    with reverts("24"):
        iETH.borrow(0, 1, 0, 1, DAI.address,
                    "0x0000000000000000000000000000000000000000", accounts[2], 0)


def testMint25(requireMainnetFork, iETH, WETH, iDAI, bzx, accounts):
    # TODO hard to reach probably thru trading
    assert True


def testMint26(requireMainnetFork, iDAI, WETH, DAI, bzx, accounts):
    # TODO This is impossible to reach since its validated in functions before that
    assert True


def testMint27(requireMainnetFork, iDAI, WETH, DAI, bzx, accounts):
    # TODO this is impossible to reach since _internalTransferFrom don't have all requires by standart
    assert True


def testMint28(requireMainnetFork, iETH, DAI, accounts):
    iETH.mintWithEther(
        accounts[1], {'from': accounts[1], 'amount':  Wei('1 ether')})
    with reverts("28"):
        iETH.borrow(0, 1, 1, Wei('1 ether'), DAI.address,
                    accounts[1], accounts[1], 0)


def testMint29(requireMainnetFork, iDAI, WETH, DAI, bzx, accounts):
    # TODO this is impossible to reach since _internalTransferFrom don't have all requires by standart
    assert True


def testMint32(requireMainnetFork, iDAI, accounts):
    with reverts("32"):
        iDAI.burn(accounts[1], 1, {'from': accounts[1]})


def testMint37(requireMainnetFork, iDAI, accounts):
    # TODO this is impossible to reach
    assert True


def testMint38(requireMainnetFork, iDAI, accounts):
    with reverts("38"):
        iDAI.flashBorrow(0, accounts[1], accounts[1], "", 0, {'from': accounts[1]})


def testMint39(requireMainnetFork, iDAI, accounts):
    with reverts("39"):
        iDAI.flashBorrow(900000000000000000000000000000, accounts[1], accounts[1], "", 0, {'from': accounts[1]})


def testMint40(requireMainnetFork, iDAI, accounts):
    with reverts("40"):
        iDAI.flashBorrow(100, accounts[1], accounts[1], "", 0, {'from': accounts[1]})

