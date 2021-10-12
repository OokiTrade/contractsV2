pragma solidity ^0.8.4;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";

contract OrderBookMarketOrders is OrderBookEvents, OrderBookStorage {
    function marketOpen(
        bytes32 loanID,
        uint256 leverage,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address iToken,
        address base,
        bytes memory loanData
    ) public {
        executeMarketOpen(
            msg.sender,
            loanID,
            leverage,
            loanTokenAmount,
            collateralTokenAmount,
            iToken,
            base,
            loanData
        );
    }

    function marketClose(
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address loanTokenAddress,
        address collateralAddress,
        bytes memory arbData
    ) public {
        executeMarketClose(
            msg.sender,
            loanID,
            amount,
            iscollateral,
            loanTokenAddress,
            collateralAddress,
            arbData
        );
    }

    function executeMarketOpen(
        address trader,
        bytes32 lID,
        uint256 leverage,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address iToken,
        address base,
        bytes memory loanData
    ) internal {
        address usedToken = collateralTokenAmount > loanTokenAmount
            ? base
            : LoanTokenI(iToken).loanTokenAddress();
        uint256 transferAmount = collateralTokenAmount > loanTokenAmount
            ? collateralTokenAmount
            : loanTokenAmount;
        SafeERC20.safeTransferFrom(
            IERC20(usedToken),
            trader,
            address(this),
            transferAmount
        );
        loanData = "";
        bytes32 loanID = LoanTokenI(iToken)
            .marginTrade(
                lID,
                leverage,
                loanTokenAmount,
                collateralTokenAmount,
                base,
                address(this),
                loanData
            )
            .LoanId;
        if (OrderEntry.inVals(ActiveTrades[trader], loanID) == false) {
            OrderEntry.addTrade(ActiveTrades[trader], loanID);
        }
    }

    function executeMarketClose(
        address trader,
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address loanTokenAddress,
        address collateralAddress,
        bytes memory arbData
    ) internal {
        address usedToken;
        arbData = "";
        if (
            (iscollateral == true && collateralAddress != wrapToken) ||
            (iscollateral == false && loanTokenAddress != wrapToken)
        ) {
            usedToken = iscollateral ? collateralAddress : loanTokenAddress;
            uint256 traderB = IERC20Metadata(usedToken).balanceOf(trader);
            SafeERC20.safeTransferFrom(
                IERC20(usedToken),
                trader,
                address(this),
                traderB
            );
        } else {
            usedToken = address(0);
        }
        if (IBZX(bZxRouterAddress).getLoan(loanID).collateral == amount) {
            OrderEntry.removeTrade(ActiveTrades[trader], loanID);
        }
        IBZX(bZxRouterAddress).closeWithSwap(
            loanID,
            address(this),
            amount,
            iscollateral,
            arbData
        );
        if (usedToken != address(0)) {
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                trader,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
        } else {
            WrappedToken(wrapToken).deposit{value: address(this).balance}();
            SafeERC20.safeTransfer(
                IERC20(wrapToken),
                trader,
                IERC20Metadata(wrapToken).balanceOf(address(this))
            );
        }
    }
}
