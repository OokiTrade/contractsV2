/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../../interfaces/IBZx.sol";
import "./AdvancedTokenStorage.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../../interfaces/IBZRXv2Converter.sol";

contract LoanTokenMigration is AdvancedTokenStorage {
    address public constant OOKI = 0xC5c66f91fE2e395078E0b872232A20981bc03B15;
    address public constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;

    function migrate(address converter) public {
        // migrates underlying BZRX
        IERC20(BZRX).approve(address(converter), 2**256 - 1);
        IBZRXv2Converter(converter).convert(address(this), IERC20(BZRX).balanceOf(address(this)));

        // rename iBZRX -> iOOKI
        loanTokenAddress = OOKI;
        name = "OOKI";
        symbol = "Fulcrum OOKI iToken";

        // migrate loanParams
        // is done separately calling `setupLoanParams`
    }
}
