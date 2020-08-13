/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./LoanTokenLogicStandard.sol";
import "../../interfaces/IChai.sol";


contract LoanTokenLogicDai is LoanTokenLogicStandard {

    uint256 constant RAY = 10 ** 27;

    // Mainnet
    /*IChai public constant chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IPot public constant pot = IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    IERC20 public constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);*/

    // Kovan
    IChai public constant chai = IChai(0x71DD45d9579A499B58aa85F50E5E3B241Ca2d10d);
    IPot public constant pot = IPot(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
    IERC20 public constant dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);


    /* Public functions */

    function mintWithChai(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            depositAmount,
            true // withChai
        );
    }

    function mint(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            depositAmount,
            false // withChai
        );
    }

    function burnToChai(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 chaiAmountPaid)
    {
        return _burnToken(
            burnAmount,
            receiver,
            true // toChai
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        return _burnToken(
            burnAmount,
            receiver,
            false // toChai
        );
    }

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data)
        external
        payable
        nonReentrant
        returns (bytes memory)
    {
        require(borrowAmount != 0, "38");

        _checkPause();

        _settleInterest();

        _dsrWithdraw(borrowAmount);

        IERC20 _dai = _getDai();

        // save before balances
        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _dai.balanceOf(address(this));

        // lock totalAssetSupply for duration of flash loan
        _flTotalAssetSupply = _underlyingBalance()
            .add(totalAssetBorrow());

        // transfer assets to calling contract
        require(_dai.transfer(
            borrower,
            borrowAmount
        ), "39");

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // arbitrary call
        (bool success, bytes memory returnData) = arbitraryCaller.call.value(msg.value)(
            abi.encodeWithSelector(
                0xde064e0d, // sendCall(address,bytes)
                target,
                callData
            )
        );
        require(success, "call failed");

        // unlock totalAssetSupply
        _flTotalAssetSupply = 0;

        // verifies return of flash loan
        require(
            address(this).balance >= beforeEtherBalance &&
            _dai.balanceOf(address(this)) >= beforeAssetsBalance,
            "40"
        );

        _dsrDeposit();

        return returnData;
    }

    // ***** NOTE: Reentrancy is allowed here to allow flashloan use cases *****
    function borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralToken,        // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory /*loanDataBytes*/) // arbitrary order data (for future use)
        public
        payable
        returns (uint256, uint256) // returns new principal and new collateral added to loan
    {
        (uint256 newPrincipal, uint256 newCollateral) = super.borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralToken,
            borrower,
            receiver,
            "" // loanDataBytes
        );

        _dsrDeposit();

        return (newPrincipal, newCollateral);
    }

    // Called to borrow and immediately get into a positions
    // ***** NOTE: Reentrancy is allowed here to allow flashloan use cases *****
    function marginTrade(
        bytes32 loanId,                 // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralToken,
        address trader,
        bytes memory loanDataBytes)     // arbitrary order data
        public
        payable
        returns (uint256, uint256) // returns new principal and new collateral added to trade
    {
        (uint256 newPrincipal, uint256 newCollateral) = super.marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralToken,
            trader,
            loanDataBytes
        );

        _dsrDeposit();

        return (newPrincipal, newCollateral);
    }


    /* Public View functions */

    // the current Maker DSR normalized to APR
    function dsr()
        public
        view
        returns (uint256)
    {
        return _getPot().dsr()
            .sub(RAY)
            .mul(31536000) // seconds in a year
            .div(10**7);
    }

    // daiAmount = chaiAmount * chaiPrice
    function chaiPrice()
        public
        view
        returns (uint256)
    {
        return _rChaiPrice()
            .div(10**9);
    }

    function totalSupplyInterestRate(
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        uint256 supplyRate = super.totalSupplyInterestRate(assetSupply);
        return supplyRate != 0 ?
            supplyRate :
            dsr();
    }


    /* Internal functions */

    function _mintToken(
        address receiver,
        uint256 depositAmount,
        bool withChai)
        internal
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        _settleInterest();

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));
        uint256 currentChaiPrice;
        IERC20 inAsset;

        if (withChai) {
            inAsset = IERC20(address(_getChai()));
            currentChaiPrice = chaiPrice();
        } else {
            inAsset = IERC20(address(_getDai()));
        }

        require(inAsset.transferFrom(
            msg.sender,
            address(this),
            depositAmount
        ), "18");

        if (withChai) {
            // convert to Dai
            depositAmount = depositAmount
                .mul(currentChaiPrice)
                .div(10**18);
        } else {
            _dsrDeposit();
        }

        mintAmount = depositAmount
            .mul(10**18)
            .div(currentPrice);

        uint256 oldBalance = balances[receiver];
        _updateCheckpoints(
            receiver,
            oldBalance,
            _mint(receiver, mintAmount, depositAmount, currentPrice), // newBalance
            currentPrice
        );
    }

    function _burnToken(
        uint256 burnAmount,
        address receiver,
        bool toChai)
        internal
        returns (uint256 amountPaid)
    {
        require(burnAmount != 0, "19");

        if (burnAmount > balanceOf(msg.sender)) {
            burnAmount = balanceOf(msg.sender);
        }

        _settleInterest();

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(10**18);

        amountPaid = loanAmountOwed;

        bool success;
        if (toChai) {
            // DSR any free DAI in the contract before Chai withdrawal
            _dsrDeposit();
            
            IChai _chai = _getChai();
            uint256 chaiBalance = _chai.balanceOf(address(this));
            
            success = _chai.move(
                address(this),
                receiver,
                amountPaid
            );

            // get Chai amount withdrawn
            amountPaid = chaiBalance
                .sub(_chai.balanceOf(address(this)));
        } else {
            _dsrWithdraw(amountPaid);
            success = _getDai().transfer(
                receiver,
                amountPaid
            );

            _dsrDeposit();
        }
        require (success, "37"); // free liquidity of DAI/CHAI insufficient

        uint256 oldBalance = balances[msg.sender];
        _updateCheckpoints(
            msg.sender,
            oldBalance,
            _burn(msg.sender, burnAmount, loanAmountOwed, currentPrice), // newBalance
            currentPrice
        );
    }

    // sentAddresses[0]: lender
    // sentAddresses[1]: borrower
    // sentAddresses[2]: receiver
    // sentAddresses[3]: manager
    // sentAmounts[0]: interestRate
    // sentAmounts[1]: newPrincipal
    // sentAmounts[2]: interestInitialAmount
    // sentAmounts[3]: loanTokenSent
    // sentAmounts[4]: collateralTokenSent
    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
        returns (uint256)
    {
        _dsrWithdraw(sentAmounts[1]);

        return super._verifyTransfers(
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            withdrawalAmount
        );
    }

    function _rChaiPrice()
        internal
        view
        returns (uint256)
    {
        IPot _pot = _getPot();

        uint256 rho = _pot.rho();
        uint256 chi = _pot.chi();
        if (now > rho) {
            chi = rmul(rpow(_pot.dsr(), now - rho, RAY), chi);
        }

        return chi;
    }

    function _dsrDeposit()
        internal
    {
        uint256 localBalance = _getDai().balanceOf(address(this));
        if (localBalance != 0) {
            _getChai().join(
                address(this),
                localBalance
            );
        }
    }

    function _dsrWithdraw(
        uint256 _value)
        internal
    {
        uint256 localBalance = _getDai().balanceOf(address(this));
        if (_value > localBalance) {
            _getChai().draw(
                address(this),
                _value - localBalance
            );
        }
    }

    function _underlyingBalance()
        internal
        view
        returns (uint256)
    {
        return rmul(
            _getChai().balanceOf(address(this)),
            _rChaiPrice())
            .add(_getDai().balanceOf(address(this)));
    }


    /* Owner-Only functions */

    function setupChai()
        public
        onlyOwner
    {
        _getDai().approve(address(_getChai()), uint256(-1));
        _dsrDeposit();
    }


    /* Internal View functions */

    // next supply interest adjustment
    function _supplyInterestRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        uint256 _dsr = dsr();
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            uint256 localBalance = _getDai().balanceOf(address(this));

            uint256 _utilRate = _utilizationRate(
                assetBorrow,
                assetSupply
                    .sub(localBalance) // DAI not DSR'ed can't be counted
            );
            _dsr = _dsr
                .mul(SafeMath.sub(100 ether, _utilRate));

            if (localBalance != 0) {
                _utilRate = _utilizationRate(
                    assetBorrow,
                    assetSupply
                );
            }

            uint256 rate = _avgBorrowInterestRate(assetBorrow)
                .mul(_utilRate)
                .mul(SafeMath.sub(10**20, ProtocolLike(bZxContract).lendingFeePercent()))
                .div(10**20);
            return rate
                .add(_dsr)
                .div(10**20);
        } else {
            return _dsr;
        }
    }

    function _getChai()
        internal
        pure
        returns (IChai)
    {
        return chai;
    }

    function _getPot()
        internal
        pure
        returns (IPot)
    {
        return pot;
    }

    function _getDai()
        internal
        pure
        returns (IERC20)
    {
        return dai;
    }

    function rmul(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 z)
    {
        require(y == 0 || (z = x * y) / y == x);
		z /= RAY;
    }
    function rpow(
        uint256 x,
        uint256 n,
        uint256 base)
        public
        pure
        returns (uint256 z)
    {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}
