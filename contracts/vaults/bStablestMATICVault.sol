pragma solidity ^0.8.0;

import "../interfaces/IVault.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.7.0/token/ERC20/ERC20.sol";
import "../interfaces/IBalancerGauge.sol";
import "../interfaces/IBalancerVault.sol";
import "../interfaces/IBalancerPool.sol";
import "../../interfaces/IPriceFeeds.sol";
contract bStablestMATICVault is ERC20, IVault {
    using SafeERC20 for IERC20;
    address public constant asset = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;

    uint256 public totalAssets;

    address internal constant _bStableGauge = 0x9928340f9E1aaAd7dF1D95E27bd9A5c715202a56;
    address internal constant _vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address public constant BAL = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

    uint256 internal _sharePrice = 1e18;

    bytes32 public constant poolId = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant STMATIC = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;

    bytes32 public constant poolIdSwap = 0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002;

    address public constant priceFeed = 0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC;

    constructor () ERC20("bStable-stMATIC/MATIC-Vault", "OVault") {}

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return assets*1e18/_sharePrice;
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        return shares*_sharePrice/1e18;
    }

    function maxDeposit(address receiver) external view returns (uint256) {
        return type(uint256).max;
    }

    //Note: Due to how compounding works with Balancer, the share amount will likely be overstated; however, there is no loss of funds as the share price will increase with it
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        compound();
        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        shares = convertToShares(assets);
        IBalancerGauge(_bStableGauge).deposit(assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function maxMint(address receiver) external view returns (uint256) {
        return type(uint256).max;
    }

    //Note: Due to how compounding works with Balancer, the asset amount will likely be understated; however, there is no loss of funds as the share price will increase with it
    function previewMint(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        compound();
        assets = convertToAssets(shares);
        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        IBalancerGauge(_bStableGauge).deposit(assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        require(msg.sender == owner, "unauthorized");
        compound();
        shares = convertToShares(assets);
        _burn(owner, shares);
        IBalancerGauge(_bStableGauge).withdraw(assets);
        IERC20(asset).transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return type(uint256).max;
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        require(msg.sender == owner, "unauthorized");
        compound();
        assets = convertToAssets(shares);
        _burn(owner, shares);
        IBalancerGauge(_bStableGauge).withdraw(assets);
        IERC20(asset).transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function setApprovals() public {
        IERC20(BAL).safeApprove(_vault, 0);
        IERC20(BAL).safeApprove(_vault, type(uint256).max);

        IERC20(WMATIC).safeApprove(_vault, 0);
        IERC20(WMATIC).safeApprove(_vault, type(uint256).max);

        IERC20(asset).safeApprove(_bStableGauge, 0);
        IERC20(asset).safeApprove(_bStableGauge, type(uint256).max);
    }

    function compound() public {
        uint256 tokensClaimed = IBalancerGauge(_bStableGauge).claimable_reward_write(address(this), BAL);
        bytes memory blank;
        IBalancerVault.SingleSwap memory swapParams = IBalancerVault.SingleSwap({
            poolId: poolIdSwap,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: BAL,
            assetOut: WMATIC,
            amount: tokensClaimed,
            userData: blank
        });
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(uint160(address(this)))),
            toInternalBalance: false
        });
        uint256 minAmountOut = IPriceFeeds(priceFeed).queryReturn(BAL, WMATIC, tokensClaimed)*985/1000;
        uint256 swapReceived = IBalancerVault(_vault).swap(swapParams, funds, minAmountOut, block.timestamp);
        uint256 joinKind = 1;
        uint256[] memory values = new uint256[](2);
        values[0] = swapReceived;
        values[1] = 0;
        address[] memory addrs = new address[](2);
        addrs[0] = WMATIC;
        addrs[1] = STMATIC;
        uint256 rateForConversion = IBalancerPool(asset).getRate();
        if (rateForConversion > 102e16 || rateForConversion < 98e16) return; //silently fail if rate from reference rate is > 2% difference. Acts as manipulation protection
        minAmountOut = IPriceFeeds(priceFeed).queryReturn(WMATIC, asset, swapReceived)*985/1000;
        IBalancerVault.JoinPoolRequest memory req = IBalancerVault.JoinPoolRequest({
            assets: addrs,
            maxAmountsIn: values,
            userData: abi.encode(joinKind, values, minAmountOut),
            fromInternalBalance: false
        });
        IBalancerVault(_vault).joinPool(poolId, address(this), address(this), req);
        IBalancerGauge(_bStableGauge).deposit(IERC20(asset).balanceOf(address(this)));
        _sharePrice = IERC20(_bStableGauge).balanceOf(address(this))/totalSupply();
    }
}