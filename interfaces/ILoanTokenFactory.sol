// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0 <0.9.0;

interface ILoanTokenFactory {
  function getRateHelper() external view returns (address);

  function getFlashLoanFeePercent() external view returns (uint256);

  function getTarget() external view returns (address);

  function isPaused(bytes calldata data) external view returns (bool);
}
