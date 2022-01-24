pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";

contract OrderBookMarketOrders is OrderBookEvents, OrderBookStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize(address target) public onlyOwner {
        _setTarget(this.marketOpen.selector, target);
        _setTarget(this.marketClose.selector, target);
    }

    function marketOpen(
        bytes32 loanID,
        uint256 leverage,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address iToken,
        address base,
        bytes memory loanDataBytes
    ) public {
        _executeMarketOpen(
            msg.sender,
            loanID,
            leverage,
            loanTokenAmount,
            collateralTokenAmount,
            iToken,
            base,
            loanDataBytes
        );
    }

    function marketClose(
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address loanTokenAddress,
        address collateralAddress,
        bytes memory loanDataBytes
    ) public {
        _executeMarketClose(
            msg.sender,
            loanID,
            amount,
            iscollateral,
            loanTokenAddress,
            collateralAddress,
            loanDataBytes
        );
    }

    function _executeMarketOpen(
        address trader,
        bytes32 lID,
        uint256 leverage,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address iToken,
        address base,
        bytes memory loanDataBytes
    ) internal {
        require(IBZx(protocol).isLoanPool(iToken));
        address usedToken = collateralTokenAmount > loanTokenAmount
            ? base
            : IToken(iToken).loanTokenAddress();
        uint256 transferAmount = collateralTokenAmount > loanTokenAmount
            ? collateralTokenAmount
            : loanTokenAmount;
        SafeERC20.safeTransferFrom(
            IERC20(usedToken),
            trader,
            address(this),
            transferAmount
        );
        loanDataBytes = "";
        bytes32 loanID = IToken(iToken)
            .marginTrade(
                lID,
                leverage,
                loanTokenAmount,
                collateralTokenAmount,
                base,
                address(this),
                loanDataBytes
            )
            .loanId;
        if (!_activeTrades[trader].contains(loanID)) {
            _activeTrades[trader].add(loanID);
        }
    }

    function _executeMarketClose(
        address trader,
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address loanTokenAddress,
        address collateralAddress,
        bytes memory loanDataBytes
    ) internal {
        address usedToken;
        loanDataBytes = "";
        if (
            (iscollateral && collateralAddress != WRAPPED_TOKEN) ||
            (!iscollateral && loanTokenAddress != WRAPPED_TOKEN)
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
        if (IBZx(protocol).getLoan(loanID).collateral == amount) {
            _activeTrades[trader].remove(loanID);
        }
        IBZx(protocol).closeWithSwap(
            loanID,
            address(this),
            amount,
            iscollateral,
            loanDataBytes
        );
        if (usedToken != address(0)) {
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                trader,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
        } else {
            WrappedToken(WRAPPED_TOKEN).deposit{value: address(this).balance}();
            SafeERC20.safeTransfer(
                IERC20(WRAPPED_TOKEN),
                trader,
                IERC20Metadata(WRAPPED_TOKEN).balanceOf(address(this))
            );
        }
    }
}
