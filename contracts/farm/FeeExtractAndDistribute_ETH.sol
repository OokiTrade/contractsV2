/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUniswapV2Router.sol";
import "../../interfaces/IBZx.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IStakingV2.sol";
import "./../staking/interfaces/ICurve3Pool.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "../governance/PausableGuardian_0_8.sol";

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

contract FeeExtractAndDistribute_ETH is PausableGuardian_0_8 {
    using SafeERC20 for IERC20;
    address public implementation;
    IStakingV2 public constant STAKING =
        IStakingV2(0x16f179f5C344cc29672A58Ea327A26F64B941a63);

    address public constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    IERC20 public constant CURVE_3CRV =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant BUYBACK =
        0x12EBd8263A54751Aaf9d8C2c74740A8e62C0AfBe;
    address public constant BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    uint64 public constant DEST_CHAINID = 137; //polygon

    IUniswapV2Router public constant UNISWAP_ROUTER =
        IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushiswap
    ICurve3Pool public constant CURVE_3POOL =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZx public constant BZX = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;
    address[] public feeTokens;
    uint256 public buybackPercent;

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

    // Fee Conversion Logic //

    function sweepFees()
        public
        pausable
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(feeTokens);
        _convertFees(feeTokens, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function sweepFees(address[] memory assets)
        public
        pausable
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
        uint256[] memory amounts = BZX.withdrawFees(
            assets,
            address(this),
            IBZx.FeeClaimType.All
        );

        for (uint256 i = 0; i < assets.length; i++) {
            stakingRewards[assets[i]] += amounts[i];
        }

        emit WithdrawFees(msg.sender);

        return amounts;
    }

    function _convertFees(address[] memory assets, uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");

        IPriceFeeds priceFeeds = IPriceFeeds(BZX.priceFeeds());
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
                daiAmount += amounts[i];
                continue;
            } else if (asset == USDC) {
                usdcAmount += amounts[i];
                continue;
            } else if (asset == USDT) {
                usdtAmount += amounts[i];
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
            stakingRewards[OOKI] += bzrxOutput;
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(CURVE_3CRV)] += crv3Output;
        }

        emit ConvertFees(msg.sender, bzrxOutput, crv3Output);
    }

    function _distributeFees()
        internal
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        bzrxRewards = stakingRewards[OOKI];
        crv3Rewards = stakingRewards[address(CURVE_3CRV)];
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
                bzrxRewards = bzrxRewards - (callerReward);
                bridgeRewards = (bzrxRewards * (buybackPercent)) / (1e20);
                USDCBridge = _convertToUSDCUniswap(bridgeRewards);
                rewardAmount = (bzrxRewards * (50e18)) / (1e20);
                IERC20(OOKI).transfer(
                    _fundsWallet,
                    bzrxRewards - rewardAmount - bridgeRewards
                );
                bzrxRewards = rewardAmount;
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(CURVE_3CRV)] = 0;
                callerReward = crv3Rewards / 100;
                CURVE_3CRV.transfer(msg.sender, callerReward);
                crv3Rewards = crv3Rewards - (callerReward);
                bridgeRewards = (crv3Rewards * (buybackPercent)) / (1e20);
                USDCBridge += _convertToUSDCCurve(bridgeRewards);
                rewardAmount = (crv3Rewards * (50e18)) / (1e20);
                CURVE_3CRV.transfer(
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
        uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
            amount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[amounts.length - 1];
        IPriceFeeds priceFeeds = IPriceFeeds(BZX.priceFeeds());
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
            stakingRewards[asset] = stakingReward - (amount);

            uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
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
        CURVE_3POOL.remove_liquidity_one_coin(amount, 1, 1); //does not need to be checked for disagreement as liquidity add handles that
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
                stakingRewards[DAI] = stakingReward - (daiAmount);
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
                stakingRewards[USDC] = stakingReward - (usdcAmount);
                curveAmounts[1] = usdcAmount;
                curveTotal += usdcAmount * 1e12; // normalize to 18 decimals
            }
        }
        if (usdtAmount != 0) {
            stakingReward = stakingRewards[USDT];
            if (stakingReward != 0) {
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward - (usdtAmount);
                curveAmounts[2] = usdtAmount;
                curveTotal += usdtAmount * 1e12; // normalize to 18 decimals
            }
        }

        uint256 beforeBalance = CURVE_3CRV.balanceOf(address(this));
        CURVE_3POOL.add_liquidity(
            curveAmounts,
            (curveTotal * 1e18 / CURVE_3POOL.get_virtual_price())*995/1000
        );
        returnAmount = CURVE_3CRV.balanceOf(address(this)) - beforeBalance;
    }

    function _checkUniDisagreement(
        address asset,
        address recvAsset,
        uint256 assetAmount,
        uint256 recvAmount,
        uint256 maxDisagreement
    ) internal view {
        uint256 estAmountOut = IPriceFeeds(BZX.priceFeeds()).queryReturn(
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
        IERC20(DAI).safeApprove(address(CURVE_3POOL), type(uint256).max);
        IERC20(USDC).safeApprove(address(CURVE_3POOL), type(uint256).max);
        IERC20(USDC).safeApprove(BRIDGE, type(uint256).max);
        IERC20(USDT).safeApprove(address(CURVE_3POOL), 0);
        IERC20(USDT).safeApprove(address(CURVE_3POOL), type(uint256).max);
        

        IERC20(OOKI).safeApprove(address(STAKING), type(uint256).max);
        IERC20(OOKI).safeApprove(address(UNISWAP_ROUTER), type(uint256).max);
        CURVE_3CRV.safeApprove(address(STAKING), type(uint256).max);
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
            uint256[] memory amountsOut = UNISWAP_ROUTER.getAmountsOut(
                1e10,
                path
            );
            require(
                amountsOut[amountsOut.length - 1] != 0,
                "path does not exist"
            );

            swapPaths[path[0]] = path;
            IERC20(path[0]).safeApprove(address(UNISWAP_ROUTER), 0);
            IERC20(path[0]).safeApprove(address(UNISWAP_ROUTER), type(uint256).max);
        }
    }

    function setBuybackSettings(uint256 amount) external onlyOwner {
        buybackPercent = amount;
    }

    function setFeeTokens(address[] calldata tokens) external onlyOwner {
        feeTokens = tokens;
    }
}
