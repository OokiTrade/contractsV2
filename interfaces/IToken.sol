/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */

pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;
// import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";

// import "contracts/interfaces/IERC20.sol";
// SPDX-License-Identifier: Apache-2.0

interface IToken {

    // IERC20 specification. hard including it to avoid compatibility of openzeppelin with different libraries
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed minter,uint256 tokenAmount,uint256 assetAmount,uint256 price);
    event Burn(address indexed burner,uint256 tokenAmount,uint256 assetAmount,uint256 price);
    event FlashBorrow(address borrower,address target,address loanToken,uint256 loanAmount);

    function tokenPrice() external view returns (uint256);

    function mint(address receiver, uint256 depositAmount)
        external
        returns (uint256);

    function burn(address receiver, uint256 burnAmount)
        external
        returns (uint256 loanAmountPaid);

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data
    ) external payable returns (bytes memory);

    function borrow(
        bytes32 loanId, // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration, // duration in seconds
        uint256 collateralTokenSent, // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes calldata loanDataBytes // arbitrary order data
    ) external payable returns (LoanOpenData memory);

    function marginTrade(
        bytes32 loanId, // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes calldata loanDataBytes // arbitrary order data
    ) external payable returns (LoanOpenData memory);

    function profitOf(address user) external view returns (int256);

    function checkpointPrice(address _user) external view returns (uint256);

    function borrowInterestRate() external view returns (uint256);

    function nextBorrowInterestRate(uint256 borrowAmount)
        external
        view
        returns (uint256);

    function supplyInterestRate() external view returns (uint256);

    function nextSupplyInterestRate(int256 supplyAmount)
        external
        view
        returns (uint256);

    function totalSupplyInterestRate(uint256 assetSupply)
        external
        view
        returns (uint256);

    function totalAssetBorrow() external view returns (uint256);

    function totalAssetSupply() external view returns (uint256);

    function assetBalanceOf(address _owner) external view returns (uint256);

    function loanTokenAddress() external view returns (address);

    function initialPrice() external view returns (uint256);

    function loanParamsIds(uint256) external view returns (bytes32);


    /// Guardian interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);
    
    function revokeApproval(address _loanTokenAddress) external;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function DOMAIN_SEPARATOR() external view returns(bytes32);
    function PERMIT_TYPEHASH() external view returns(bytes32);
    function nonces(address) external view returns (uint);
    /// Admin functions
    function setTarget(address _newTarget) external;
    
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function initializeDomainSeparator() external;

    struct LoanOpenData {
        bytes32 loanId;
        uint256 principal;
        uint256 collateral;
    }
	
    //flash borrow fees
    function updateFlashBorrowFeePercent(uint256 newFeePercent) external;

    function setDemandCurve(address _rateHelper) external; 

    function getPoolUtilization()
        external
        view
    returns (uint256);

    function name() external view returns (string memory);
 
    function symbol() external view  returns (string memory);

    function mintWithEther(address receiver) external payable;

    function burnToEther(address payable receiver,uint256 burnAmount) external returns (uint256 loanAmountPaid);
}
