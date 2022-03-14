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
    ) external pausable {
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
        bytes memory loanDataBytes
    ) external pausable {
        _executeMarketClose(
            msg.sender,
            loanID,
            amount,
            iscollateral,
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
        require(protocol.isLoanPool(iToken), "OrderBook: Not an iToken Contract");
        (address usedToken, uint256 transferAmount) = collateralTokenAmount > loanTokenAmount
            ? (base, collateralTokenAmount)
            : (IToken(iToken).loanTokenAddress(), loanTokenAmount);
        SafeERC20.safeTransferFrom(
            IERC20(usedToken),
            trader,
            address(this),
            transferAmount
        );
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

    function _isActiveLoan(bytes32 ID) internal view returns (bool) {
        return protocol.loans(ID).active;
    }

    function _executeMarketClose(
        address trader,
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        bytes memory loanDataBytes
    ) internal {
        protocol.closeWithSwap(
            loanID,
            trader,
            amount,
            iscollateral,
            loanDataBytes
        );
        if (!_isActiveLoan(loanID)) {
            _activeTrades[trader].remove(loanID);
        }
    }
}
