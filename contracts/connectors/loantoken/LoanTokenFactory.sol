/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/governance/PausableGuardian_0_8.sol";
import "interfaces/IToken.sol";
import "interfaces/IBZx.sol";
import "contracts/connectors/loantoken/LoanTokenLogicStandard.sol";
import "contracts/connectors/loantoken/LoanTokenDoubleProxy.sol";
import "@openzeppelin-4.9.3/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-4.9.3/utils/Create2.sol";
// import "contracts/interfaces/ISignatureHelper.sol"; // TODO why the hell do we need this @drypto?

contract LoanTokenFactory is PausableGuardian_0_8 {
  // IBZx public constant PROTOCOL = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f); // mainnet
  // IBZx public constant PROTOCOL = IBZx(0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f); // bsc
  // IBZx public constant PROTOCOL = IBZx(0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8); // polygon
  // IBZx public immutable constant PROTOCOL = IBZx(0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB); // arbitrum
  // IBZx public constant PROTOCOL = IBZx(0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1); // optimism
  IBZx public immutable PROTOCOL;
  address public immutable TIMELOCK;
  address public immutable GUARDIAN;
  // address public constant SIG_HELPER = 0x888B54Ee4eD8D1B699F19F89146842147F16cA89; //Arbitrum
  // address public rateHelper;
  // uint256 flashLoanFeePercent;
  // address public target;
  address public immutable ltlsdProxyImpl; // TODO create setter - this is a proxy in in itself
  address public immutable ltlsdProxyAdmin; // TODO owned by timelock
  address public immutable cirProxy; // TODO also double proxy

  constructor(address _PROTOCOL, address _TIMELOCK, address _GUARDIAN, address _ltlsdProxyImpl, address _ltlsdProxyAdmin, address _cirProxy) {
    PROTOCOL = IBZx(_PROTOCOL);
    TIMELOCK = _TIMELOCK;
    GUARDIAN = _GUARDIAN;
    ltlsdProxyImpl = _ltlsdProxyImpl;
    ltlsdProxyAdmin = _ltlsdProxyAdmin;
    cirProxy = _cirProxy;
  }

  function addNewToken(address loanTokenAddress, bytes32 salt) external returns(address iToken){
    iToken = deployIToken(salt);
    initIToken(iToken, loanTokenAddress);
    initITokenRoles(iToken);
    // initProtocolSettings(iToken, loanTokenAddress);
  }

  function deployIToken(bytes32 salt) public returns (address newIToken) {
    bytes memory bytecode = abi.encodePacked(type(LoanTokenDoubleProxy).creationCode, abi.encode(ltlsdProxyImpl, ltlsdProxyImpl, ''));
    newIToken = Create2.deploy(0, salt, bytecode);
  }

  function initProtocolSettings(address iToken, address loanTokenAddress) internal {
    address[] memory pools = new address[](1);
    pools[0] = iToken;
    address[] memory assets = new address[](1);
    assets[0] = loanTokenAddress;
    PROTOCOL.setLoanPool(pools, assets);
    address[] memory addrs = new address[](1);
    addrs[0] = loanTokenAddress;
    bool[] memory toggles = new bool[](1);
    toggles[0] = true;
    PROTOCOL.setSupportedTokens(addrs, toggles, true);
    PROTOCOL.setupLoanPoolTWAI(iToken);
  }

  function initIToken(address iToken, address loanTokenAddress) internal {
    string memory symbol = string(abi.encodePacked("i", IERC20Metadata(loanTokenAddress).symbol()));
    string memory name = string(abi.encodePacked(IERC20Metadata(loanTokenAddress).name(), " iToken"));
    // IToken(iToken).initialize(loanTokenAddress, name, symbol);
  }

  function initITokenRoles(address iToken) internal {
    IToken(iToken).grantRole(IToken(iToken).GUARDIAN_ROLE(), GUARDIAN);
    IToken(iToken).grantRole(IToken(iToken).TIMELOCK_ROLE(), TIMELOCK);
    IToken(iToken).revokeRole(0x0000000000000000000000000000000000000000000000000000000000000000, address(this));
  }

  // function getRateHelper() external view returns (address) {
  //   return rateHelper;
  // }

  // function getFlashLoanFeePercent() external view returns (uint256) {
  //   return flashLoanFeePercent;
  // }

  // function getTarget() external view returns (address) {
  //   return target;
  // }

  // function setRateHelper(address helper) external onlyGuardian {
  //   rateHelper = helper;
  // }

  // function setFlashLoanFeePercent(uint256 percent) external onlyOwner {
  //   flashLoanFeePercent = percent;
  // }

  // function setTarget(address newTarget) external onlyOwner {
  //   target = newTarget;
  // }

  // function setWhitelistTarget(address newTarget) external onlyOwner {
  //   whitelistedITokenTarget = newTarget;
  // }

  // function convertITokenToWhitelisted(
  //   address payable iTokenAddress,
  //   address _rateHelper,
  //   uint256 flashLoanFee
  // ) external onlyOwner {
  //   // TODO
  // //   FactoryLoanToken f = FactoryLoanToken(iTokenAddress);
  // //   f.setTarget(whitelistedITokenTarget);
  // //   f.setFactory(address(0));
  // //   IToken(iTokenAddress).setDemandCurve(_rateHelper);
  // //   IToken(iTokenAddress).updateFlashBorrowFeePercent(flashLoanFee);
  // //   f.transferOwnership(owner());
  // }

  // function isPaused(bytes calldata data) external view returns (bool) {
  //   return _isPaused(ISignatureHelper(SIG_HELPER).getSig(data)); //slice to get signature
  // }
}
