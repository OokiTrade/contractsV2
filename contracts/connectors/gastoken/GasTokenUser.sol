/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../loantoken/interfaces/ProtocolLike.sol";
import "../../feeds/IPriceFeeds.sol";
import "../../openzeppelin/SafeMath.sol";

contract ITokenHolderLike {
    function balanceOf(address _who) public view returns (uint256);

    function freeUpTo(uint256 value) public returns (uint256);

    function freeFromUpTo(address from, uint256 value) public returns (uint256);
}

contract GasTokenUser {
    using SafeMath for uint256;
    ITokenHolderLike public constant gasToken =
        ITokenHolderLike(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    ITokenHolderLike public constant tokenHolder =
        ITokenHolderLike(0x55Eb3DD3f738cfdda986B8Eff3fa784477552C61);

    modifier usesGasToken(address holder) {
        if (holder == address(0)) {
            holder = address(tokenHolder);
        }

        if (gasToken.balanceOf(holder) != 0) {
            uint256 gasCalcValue = gasleft();

            _;

            gasCalcValue = (_gasUsed(gasCalcValue) + 14154) / 41947;

            if (holder == address(tokenHolder)) {
                tokenHolder.freeUpTo(gasCalcValue);
            } else {
                tokenHolder.freeFromUpTo(holder, gasCalcValue);
            }
        } else {
            _;
        }
    }

    event GasRebate(
        address receiver,
        uint256 amount
    );

    modifier withGasRebate(address receiver, address bZxContract) {
        uint256 startingGas = gasleft() + 21000 + 0; // starting gas + 0 the amount is so minuscule I am ignoring it for now, it varies between different functions
        _;

        ProtocolLike BZX = ProtocolLike(bZxContract);
        address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        // gets the gas rebate denominated in collateralToken
        uint256 gasRebate = SafeMath
        .mul(
            IPriceFeeds(BZX.priceFeeds()).getFastGasPrice(WMATIC),
            startingGas - gasleft()
        ).div(1e18 * 1e18);
        emit GasRebate(receiver, gasRebate);
        BZX.withdraw(receiver, gasRebate);
    }

    function _gasUsed(uint256 startingGas) internal view returns (uint256) {
        return 21000 + startingGas - gasleft() + 16 * msg.data.length;
    }
}
