/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "../interfaces/IERC20Burnable.sol";
import "./interfaces/Upgradeable.sol";
import "./interfaces/IWethERC20.sol";
import "./interfaces/IUniswapV2Router.sol";
import "../../interfaces/IBZx.sol";
import "./interfaces/IMasterChefPartial.sol";
import "./interfaces/IPriceFeeds.sol";
import "../../interfaces/IStakingV2.sol";
import "./../staking/interfaces/ICurve3Pool.sol";

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;
}

contract FeeExtractAndDistribute_ETH is Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IStakingV2 public constant STAKING =
        IStakingV2(0x16f179f5C344cc29672A58Ea327A26F64B941a63);

    address public constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    IERC20 public constant curve3Crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant BUYBACK =
        0x12EBd8263A54751Aaf9d8C2c74740A8e62C0AfBe;
    address public constant BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    uint64 public constant DEST_CHAINID = 137; //polygon

    IUniswapV2Router public constant uniswapRouter =
        IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushiswap
    ICurve3Pool public constant curve3pool =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZx public constant bZx = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;

    uint256 public buybackPercent;
    bool isPaused;

    event ExtractAndDistribute();

    event WithdrawFees(address indexed sender);

    event DistributeFees(
        address indexed sender,
        uint256 bzrxRewards,
        uint256 stableCoinRewards
    );

    event ConvertFees(
        address indexed sender,
        uint256 bzrxOutput,
        uint256 stableCoinOutput
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused || msg.sender == owner(), "paused");
        _;
    }

    // Fee Conversion Logic //

    function sweepFees()
        public
        returns (
            // sweepFeesByAsset() does checkPause
            uint256 bzrxRewards,
            uint256 crv3Rewards
        )
    {
        return sweepFeesByAsset(STAKING.getCurrentFeeTokens());
    }

    function sweepFeesByAsset(address[] memory assets)
        public
        checkPause
        onlyEOA
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function _withdrawFees(address[] memory assets)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amounts = bZx.withdrawFees(
            assets,
            address(this),
            IBZx.FeeClaimType.All
        );

        for (uint256 i = 0; i < assets.length; i++) {
            stakingRewards[assets[i]] = stakingRewards[assets[i]].add(
                amounts[i]
            );
        }

        emit WithdrawFees(msg.sender);

        return amounts;
    }

    function _convertFees(address[] memory assets, uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");

        IPriceFeeds priceFeeds = IPriceFeeds(bZx.priceFeeds());
        //(uint256 bzrxRate, ) = priceFeeds.queryRate(OOKI, WETH);
        uint256 maxDisagreement = 1e18;
        address asset;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 usdtAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == OOKI) {
                continue;
            } else if (asset == DAI) {
                daiAmount = daiAmount.add(amounts[i]);
                continue;
            } else if (asset == USDC) {
                usdcAmount = usdcAmount.add(amounts[i]);
                continue;
            } else if (asset == USDT) {
                usdtAmount = usdtAmount.add(amounts[i]);
                continue;
            }

            if (amounts[i] != 0) {
                bzrxOutput += _convertFeeWithUniswap(
                    asset,
                    amounts[i],
                    priceFeeds,
                    0, /*bzrxRate*/
                    maxDisagreement
                );
            }
        }
        if (bzrxOutput != 0) {
            stakingRewards[OOKI] = stakingRewards[OOKI].add(bzrxOutput);
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(curve3Crv)] = stakingRewards[
                address(curve3Crv)
            ].add(crv3Output);
        }

        emit ConvertFees(msg.sender, bzrxOutput, crv3Output);
    }

    function _distributeFees()
        internal
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        bzrxRewards = stakingRewards[OOKI];
        crv3Rewards = stakingRewards[address(curve3Crv)];
        uint256 USDCBridge = 0;
        if (bzrxRewards != 0 || crv3Rewards != 0) {
            address _fundsWallet = 0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc;
            uint256 rewardAmount;
            uint256 callerReward;
            uint256 bridgeRewards;
            if (bzrxRewards != 0) {
                stakingRewards[OOKI] = 0;
                callerReward = bzrxRewards / 100;
                IERC20(OOKI).transfer(msg.sender, callerReward);
                bzrxRewards = bzrxRewards.sub(callerReward);
                bridgeRewards = bzrxRewards.mul(buybackPercent).div(1e20);
                USDCBridge = _convertToUSDCUniswap(bridgeRewards);
                rewardAmount = bzrxRewards.mul(50e18).div(1e20);
                IERC20(OOKI).transfer(
                    _fundsWallet,
                    bzrxRewards - rewardAmount - bridgeRewards
                );
                bzrxRewards = rewardAmount;
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(curve3Crv)] = 0;
                callerReward = crv3Rewards / 100;
                curve3Crv.transfer(msg.sender, callerReward);
                crv3Rewards = crv3Rewards.sub(callerReward);
                bridgeRewards = crv3Rewards.mul(buybackPercent).div(1e20);
                USDCBridge = USDCBridge.add(_convertToUSDCCurve(bridgeRewards));
                rewardAmount = crv3Rewards.mul(50e18).div(1e20);
                curve3Crv.transfer(
                    _fundsWallet,
                    crv3Rewards - rewardAmount - bridgeRewards
                );
                crv3Rewards = rewardAmount;
            }
            STAKING.addRewards(bzrxRewards, crv3Rewards);
            _bridgeFeesToPolygon(USDCBridge);
        }

        emit DistributeFees(msg.sender, bzrxRewards, crv3Rewards);
    }

    function _bridgeFeesToPolygon(uint256 bridgeAmount) internal {
        IBridge(BRIDGE).send(
            BUYBACK,
            USDC,
            bridgeAmount,
            DEST_CHAINID,
            uint64(block.timestamp),
            10000
        );
    }

    function _convertToUSDCUniswap(uint256 amount)
        internal
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](3);
        path[0] = OOKI;
        path[1] = WETH;
        path[2] = USDC;
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[amounts.length - 1];
        IPriceFeeds priceFeeds = IPriceFeeds(bZx.priceFeeds());
        //(uint256 bzrxRate, ) = priceFeeds.queryRate(OOKI, WETH);
        /*_checkUniDisagreement(
            OOKI,
			USDC,
            amount,
            returnAmount,
            STAKING.maxUniswapDisagreement()
        );*/
    }

    function _convertFeeWithUniswap(
        address asset,
        uint256 amount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement
    ) internal returns (uint256 returnAmount) {
        uint256 stakingReward = stakingRewards[asset];
        if (stakingReward != 0) {
            if (amount > stakingReward) {
                amount = stakingReward;
            }
            stakingRewards[asset] = stakingReward.sub(amount);

            uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
                amount,
                1, // amountOutMin
                swapPaths[asset],
                address(this),
                block.timestamp
            );

            returnAmount = amounts[amounts.length - 1];

            // will revert if disagreement found
            /*_checkUniDisagreement(
                asset,
				OOKI,
                amount,
                returnAmount,
                maxDisagreement
            );*/
        }
    }

    function _convertToUSDCCurve(uint256 amount)
        internal
        returns (uint256 returnAmount)
    {
        uint256 beforeBalance = IERC20(USDC).balanceOf(address(this));
        curve3pool.remove_liquidity_one_coin(amount, 1, 1); //does not need to be checked for disagreement as liquidity add handles that
        returnAmount = IERC20(USDC).balanceOf(address(this)) - beforeBalance; //does not underflow as USDC is not being transferred out
    }

    function _convertFeesWithCurve(
        uint256 daiAmount,
        uint256 usdcAmount,
        uint256 usdtAmount
    ) internal returns (uint256 returnAmount) {
        uint256[3] memory curveAmounts;
        uint256 curveTotal;
        uint256 stakingReward;

        if (daiAmount != 0) {
            stakingReward = stakingRewards[DAI];
            if (stakingReward != 0) {
                if (daiAmount > stakingReward) {
                    daiAmount = stakingReward;
                }
                stakingRewards[DAI] = stakingReward.sub(daiAmount);
                curveAmounts[0] = daiAmount;
                curveTotal = daiAmount;
            }
        }
        if (usdcAmount != 0) {
            stakingReward = stakingRewards[USDC];
            if (stakingReward != 0) {
                if (usdcAmount > stakingReward) {
                    usdcAmount = stakingReward;
                }
                stakingRewards[USDC] = stakingReward.sub(usdcAmount);
                curveAmounts[1] = usdcAmount;
                curveTotal = curveTotal.add(usdcAmount.mul(1e12)); // normalize to 18 decimals
            }
        }
        if (usdtAmount != 0) {
            stakingReward = stakingRewards[USDT];
            if (stakingReward != 0) {
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward.sub(usdtAmount);
                curveAmounts[2] = usdtAmount;
                curveTotal = curveTotal.add(usdtAmount.mul(1e12)); // normalize to 18 decimals
            }
        }

        uint256 beforeBalance = curve3Crv.balanceOf(address(this));
        curve3pool.add_liquidity(
            curveAmounts,
            curveTotal
                .mul(curve3pool.get_virtual_price())
                .div(1e18)
                .mul(99e18)
                .div(1e20)
        );

        returnAmount = curve3Crv.balanceOf(address(this)) - beforeBalance;
    }

    function _checkUniDisagreement(
        address asset,
        address recvAsset,
        uint256 assetAmount,
        uint256 recvAmount,
        uint256 maxDisagreement
    ) internal view {
        uint256 estAmountOut = IPriceFeeds(bZx.priceFeeds()).queryReturn(
            asset,
            recvAsset,
            assetAmount
        );

        uint256 spreadValue = estAmountOut > recvAmount
            ? estAmountOut - recvAmount
            : recvAmount - estAmountOut;
        if (spreadValue != 0) {
            spreadValue = (spreadValue * 1e20) / estAmountOut;

            require(
                spreadValue <= maxDisagreement,
                "uniswap price disagreement"
            );
        }
    }

    function setApprovals() external onlyOwner {
        IERC20(DAI).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDC).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDC).safeApprove(BRIDGE, uint256(-1));
        IERC20(USDT).safeApprove(address(curve3pool), uint256(-1));

        IERC20(OOKI).safeApprove(address(STAKING), uint256(-1));
        IERC20(OOKI).safeApprove(address(uniswapRouter), uint256(-1));
        curve3Crv.safeApprove(address(STAKING), uint256(-1));
    }

    // path should start with the asset to swap and end with OOKI
    // only one path allowed per asset
    // ex: asset -> WETH -> OOKI
    function setPaths(address[][] calldata paths) external onlyOwner {
        address[] memory path;
        for (uint256 i = 0; i < paths.length; i++) {
            path = paths[i];
            require(
                path.length >= 2 &&
                    path[0] != path[path.length - 1] &&
                    path[path.length - 1] == OOKI,
                "invalid path"
            );

            // check that the path exists
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
                1e10,
                path
            );
            require(
                amountsOut[amountsOut.length - 1] != 0,
                "path does not exist"
            );

            swapPaths[path[0]] = path;
            IERC20(path[0]).safeApprove(address(uniswapRouter), 0);
            IERC20(path[0]).safeApprove(address(uniswapRouter), uint256(-1));
        }
    }

    function setBuybackSettings(uint256 amount) external onlyOwner {
        buybackPercent = amount;
    }

    function togglePause(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }
}
