pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../events/LoanClosingsEvents.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestHandler.sol";
import "../../mixins/LiquidationHelper.sol";
import "../../swaps/SwapsUser.sol";
import "../../interfaces/ILoanPool.sol";
import "../../governance/PausableGuardian.sol";

contract LoanClosingsBase_2 is State, LoanClosingsEvents, VaultController, InterestHandler, SwapsUser, LiquidationHelper, PausableGuardian {

    enum CloseTypes {
        Deposit,
        Swap,
        Liquidation
    }

    function _getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        bool silentFail)
        internal
        returns (uint256 currentMargin, uint256 collateralToLoanRate)
    {
        address _priceFeeds = priceFeeds;
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanToken,
                collateralToken,
                principal,
                collateral
            )
        );
        if (success) {
            assembly {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        } else {
            require(silentFail, "margin query failed");
        }
    }

    // The receiver always gets back an ERC20 (even WETH)
    function _returnPrincipalWithDeposit(
        address loanToken,
        address receiver,
        uint256 principalNeeded)
        internal
    {
        if (principalNeeded != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    receiver,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wethToken.deposit.value(principalNeeded)();
                if (receiver != address(this)) {
                    vaultTransfer(
                        loanToken,
                        address(this),
                        receiver,
                        principalNeeded
                    );
                }
                if (msg.value > principalNeeded) {
                    // refund overage
                    Address.sendValue(
                        msg.sender,
                        msg.value - principalNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }

    function _closeLoan(
        Loan memory loanLocal,
        address loanToken,
        uint256 loanCloseAmount)
        internal
        returns (uint256 principalBefore, uint256 principalAfter)
    {
        require(loanCloseAmount != 0, "nothing to close");

        principalBefore = loanLocal.principal;
        uint256 loanInterest = loanInterestTotal[loanLocal.id];

        if (loanCloseAmount == principalBefore.add(loanInterest)) {
            poolPrincipalTotal[loanLocal.lender] = poolPrincipalTotal[loanLocal.lender]
                .sub(principalBefore);
            loanLocal.principal = 0;

            loanInterestTotal[loanLocal.id] = 0;

            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
        } else {
            // interest is paid before principal
            if (loanCloseAmount >= loanInterest) {
                principalAfter = principalBefore.sub(loanCloseAmount - loanInterest);

                loanLocal.principal = principalAfter;
                poolPrincipalTotal[loanLocal.lender] = poolPrincipalTotal[loanLocal.lender]
                    .sub(loanCloseAmount - loanInterest);

                loanInterestTotal[loanLocal.id] = 0;
            } else {
                principalAfter = principalBefore;
                loanInterestTotal[loanLocal.id] = loanInterest - loanCloseAmount;
                loanInterest = loanCloseAmount;
            }
        }

        uint256 poolInterest = poolInterestTotal[loanLocal.lender];
        if (poolInterest > loanInterest) {
            poolInterestTotal[loanLocal.lender] = poolInterest - loanInterest;
        }
        else {
            poolInterestTotal[loanLocal.lender] = 0;
        }

        // pay fee
        _payLendingFee(
            loanLocal.lender,
            loanToken,
            _getLendingFee(loanInterest)
        );

        loans[loanLocal.id] = loanLocal;
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanRate,
        uint256 collateralToLoanSwapRate,
        uint256 currentMargin,
        CloseTypes closeType)
        internal
    {
        if (closeType == CloseTypes.Deposit) {
            emit CloseWithDeposit(
                loanLocal.borrower,                             // user (borrower)
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                msg.sender,                                     // closer
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        } else if (closeType == CloseTypes.Swap) {
            // exitPrice = 1 / collateralToLoanSwapRate
            if (collateralToLoanSwapRate != 0) {
                collateralToLoanSwapRate = SafeMath.div(WEI_PRECISION * WEI_PRECISION, collateralToLoanSwapRate);
            }

            // currentLeverage = 100 / currentMargin
            if (currentMargin != 0) {
                currentMargin = SafeMath.div(10**38, currentMargin);
            }

            emit CloseWithSwap(
                loanLocal.borrower,                             // user (trader)
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.collateralToken,                // collateralToken
                loanParamsLocal.loanToken,                      // loanToken
                msg.sender,                                     // closer
                collateralCloseAmount,                          // positionCloseSize
                loanCloseAmount,                                // loanCloseAmount
                collateralToLoanSwapRate,                       // exitPrice (1 / collateralToLoanSwapRate)
                currentMargin                                   // currentLeverage
            );
        } else { // closeType == CloseTypes.Liquidation
            emit Liquidate(
                loanLocal.borrower,                             // user (borrower)
                msg.sender,                                     // liquidator
                loanLocal.id,                                   // loanId
                loanLocal.lender,                               // lender
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        }
    }

    // withdraws asset to receiver
    function _withdrawAsset(
        address assetToken,
        address receiver,
        uint256 assetAmount)
        internal
    {
        if (assetAmount != 0) {
            if (assetToken == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    assetAmount
                );
            } else {
                vaultWithdraw(
                    assetToken,
                    receiver,
                    assetAmount
                );
            }
        }
    }
}