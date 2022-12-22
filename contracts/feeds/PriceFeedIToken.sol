// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './IPriceFeedsExt.sol';
import '../../interfaces/IToken.sol';

contract PriceFeedIToken {
  IPriceFeedsExt public priceFeedAddress; // underlying token Chainlink feed address
  IToken public iTokenAddress;

  constructor(IPriceFeedsExt _priceFeedAddress, IToken _iTokenAddress) {
    priceFeedAddress = _priceFeedAddress;
    iTokenAddress = _iTokenAddress;
  }

  function latestAnswer() public view returns (int256) {
    return
      (priceFeedAddress.latestAnswer() * int256(iTokenAddress.tokenPrice())) /
      1e18;
  }
}
