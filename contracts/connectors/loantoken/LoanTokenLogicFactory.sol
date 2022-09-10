pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanTokenLogicStandard.sol";
import "../../../interfaces/ILoanTokenFactory.sol";
contract LoanTokenLogicFactory is LoanTokenLogicStandard {

    address public constant FACTORY = address(0);

    modifier onlyFactory() {
        require(msg.sender == FACTORY, "not factory");_;
    }

    constructor()
        public
        LoanTokenLogicStandard()
    {}

    function initialize(
        address _loanTokenAddress,
        string memory _name,
        string memory _symbol)
        public
        onlyFactory
    {
        loanTokenAddress = _loanTokenAddress;

        name = _name;
        symbol = _symbol;
        decimals = IERC20Detailed(loanTokenAddress).decimals();

        if (initialPrice == 0) {
            initialPrice = WEI_PRECISION; // starting price of 1
        }

        IERC20(_loanTokenAddress).safeApprove(bZxContract, uint256(-1));
    }

    function setDemandCurve(ICurvedInterestRate _rateHelper) public {} //overrides LoanTokenLogicStandard

    function updateFlashBorrowFeePercent(uint256 newFeePercent) public {} //overrides LoanTokenLogicStandard

    function _getRateHelper()
        internal
        view
        returns (ICurvedInterestRate)
    {
        return ICurvedInterestRate(ILoanTokenFactory(FACTORY).getRateHelper());
    }

    function _getFlashLoanFee()
        internal
        view
        returns (uint256)
    {
        ILoanTokenFactory(FACTORY).getFlashLoanFeePercent();
    }
}