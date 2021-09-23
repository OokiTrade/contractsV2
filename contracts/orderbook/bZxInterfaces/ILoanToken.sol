pragma solidity ^0.8.4;

abstract contract LoanTokenI {
    struct LoanOpenData {
        bytes32 LoanId;
        uint256 principal;
        uint256 collateral;
    }
    address public loanTokenAddress;

    function marginTrade(
        bytes32 loanId,
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes
    ) external payable virtual returns (LoanOpenData memory);
}
