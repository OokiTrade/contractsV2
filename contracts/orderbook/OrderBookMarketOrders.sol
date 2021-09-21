pragma solidity ^0.8.4;
import "./OrderBookEvents.sol";
import "./OrderBookStorage.sol";


contract OrderBookMarketOrders is OrderBookEvents,OrderBookStorage,safeTransfers{
	function marketOpen(bytes32 loanID, uint256 leverage, uint256 loanTokenAmount, uint256 collateralTokenAmount, address iToken, address base, bytes memory loanData) public{
		executeMarketOpen(msg.sender,loanID,leverage,loanTokenAmount,collateralTokenAmount,iToken,base,loanData);
	}
	function marketClose(bytes32 loanID, uint amount, bool iscollateral,address loanTokenAddress, address collateralAddress,bytes memory arbData) public{
		executeMarketClose(msg.sender,loanID,amount,iscollateral,loanTokenAddress,collateralAddress,arbData);
	}
    function executeMarketOpen(address trader, bytes32 lID, uint256 leverage, uint256 loanTokenAmount, uint256 collateralTokenAmount, address iToken, address base, bytes memory loanData) internal{
		address usedToken = collateralTokenAmount > loanTokenAmount ? base : LoanTokenI(iToken).loanTokenAddress();

		_safeTransferFrom(usedToken,trader,address(this),IERC20Metadata(usedToken).balanceOf(trader),"");

		bytes32 loanID = LoanTokenI(iToken).marginTrade(lID,leverage,loanTokenAmount,collateralTokenAmount,base,address(this),loanData).LoanId;
		if(getTrades.inVals(ActiveTrades[trader],loanID) == false){
			getTrades.addTrade(ActiveTrades[trader],loanID);
		}
    }
	function executeMarketClose(address trader, bytes32 loanID, uint amount, bool iscollateral,address loanTokenAddress, address collateralAddress,bytes memory arbData) internal{
		address usedToken;
		if((iscollateral == true && collateralAddress != BNBAddress) || (iscollateral == false && loanTokenAddress != BNBAddress)){
			usedToken = iscollateral ? collateralAddress : loanTokenAddress;
			uint traderB = IERC20Metadata(usedToken).balanceOf(trader);
			_safeTransferFrom(usedToken,trader,address(this),traderB,"");
		}else{
			usedToken = address(0);
		}
		if(IBZX(bZxRouterAddress).getLoan(loanID).collateral == amount){
				getTrades.removeTrade(ActiveTrades[trader],loanID);
		}
        IBZX(bZxRouterAddress).closeWithSwap(loanID, address(this), amount, iscollateral, arbData);
	}
}