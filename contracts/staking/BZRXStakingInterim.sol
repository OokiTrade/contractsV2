/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../openzeppelin/Ownable.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/SafeERC20.sol";
import "../mixins/EnumerableBytes32Set.sol";


contract BZRXStakingInterim is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value
    mapping(address => mapping(address => uint256)) internal _checkpointPerToken;   // token => account => value

    mapping(address => address) public repDelegate;                                 // user => delegate
    mapping(address => mapping(address => uint256)) public repStakedPerToken;       // token => wallet => value
    mapping(address => bool) public reps;                                           // wallet => isActive
    EnumerableBytes32Set.Bytes32Set internal repStakedSet;

    mapping(address => uint256) public rewardsPerTokenStored;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event DelegateChanged(
        address indexed user,
        address indexed oldDelegate,
        address indexed newDelegate
    );

    modifier checkActive() {
        require(isActive, "not active");
        _;
    }

    address public BZRX;
    address public vBZRX;
    address public LPToken;

    uint256 constant public initialCirculatingSupply = 1030000000e18 - 889389933e18;

    uint256 constant public normalizedRewardRate = 1e9;

    address internal constant ZERO_ADDRESS = address(0);

    uint256 public lastUpdateTime;

    bool public isActive;

    constructor(
        address _BZRX,
        address _vBZRX,
        address _LPToken,
        bool _isActive)
        public
    {
        BZRX = _BZRX;
        vBZRX = _vBZRX;
        LPToken = _LPToken;

        isActive = _isActive;
    }

    function setActive(
        bool _isActive)
        public
        onlyOwner
    {
        isActive = _isActive;
    }

    function rescueToken(
        IERC20 token,
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (uint256 withdrawAmount)
    {
        withdrawAmount = token.balanceOf(address(this));
        if (withdrawAmount > amount) {
            withdrawAmount = amount;
        }
        if (withdrawAmount != 0) {
            token.safeTransfer(
                receiver,
                withdrawAmount
            );
        }
    }

    function stake(
        address[] memory tokens,
        uint256[] memory values)
        public
    {
        stakeWithDelegate(
            tokens,
            values,
            ZERO_ADDRESS
        );
    }

    function stakeWithDelegate(
        address[] memory tokens,
        uint256[] memory values,
        address delegateToSet)
        public
        checkActive
        updateReward(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = _setRepDelegate(delegateToSet);

        address token;
        uint256 stakeAmount;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            stakeAmount = values[i];

            if (stakeAmount == 0) {
                continue;
            }

            require(token == BZRX || token == vBZRX || token == LPToken, "invalid token");
            require(stakeAmount <= stakeableByAsset(token, msg.sender), "insufficient balance");

            _balancesPerToken[token][msg.sender] = _balancesPerToken[token][msg.sender].add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(stakeAmount);

            emit Staked(
                msg.sender,
                token,
                currentDelegate,
                stakeAmount
            );

            repStakedSet.addAddress(currentDelegate); // will not duplicate
            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .add(stakeAmount);
        }
    }

    function setRepActive(
        bool _isActive)
        public
    {
        reps[msg.sender] = _isActive;
    }

    struct RepStakedTokens {
        address wallet;
        uint256 BZRX;
        uint256 vBZRX;
        uint256 LPToken;
    }
    function getRepVotes(
        uint256 start,
        uint256 count,
        bool activeOnly)
        external
        view
        returns (RepStakedTokens[] memory repStakedArr)
    {
        uint256 end = start.add(count).min256(repStakedSet.length());
        if (start >= end) {
            return repStakedArr;
        }
        count = end-start;

        uint256 idx = count;
        address wallet;
        repStakedArr = new RepStakedTokens[](idx);
        for (uint256 i = --end; i >= start; i--) {
            wallet = repStakedSet.getAddress(i);
            if (activeOnly && !reps[wallet]) {
                if (i == 0) {
                    break;
                } else {
                    continue;
                }
            }

            repStakedArr[count-(idx--)] = RepStakedTokens({
                wallet: wallet,
                BZRX: repStakedPerToken[wallet][BZRX],
                vBZRX: repStakedPerToken[wallet][vBZRX],
                LPToken: repStakedPerToken[wallet][LPToken]
            });

            if (i == 0) {
                break;
            }
        }

        if (idx != 0) {
            count -= idx;
            assembly {
                mstore(repStakedArr, count)
            }
        }
    }

    modifier updateReward(address account) {
        (uint256 bzrxReward,
         uint256 vbzrxReward,
         uint256 lptokenReward) = rewardsPerToken();

        rewardsPerTokenStored[BZRX] = bzrxReward;
        rewardsPerTokenStored[vBZRX] = vbzrxReward;
        rewardsPerTokenStored[LPToken] = lptokenReward;

        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = _earned(account, bzrxReward, vbzrxReward, lptokenReward);
            userRewardPerTokenPaid[account][BZRX] = bzrxReward;
            userRewardPerTokenPaid[account][vBZRX] = vbzrxReward;
            userRewardPerTokenPaid[account][LPToken] = lptokenReward;
        }
        _;
    }

    function rewardsPerToken()
        public
        view
        returns (uint256 bzrxReward, uint256 vbzrxReward, uint256 lptokenReward)
    {
        uint256 totalSupplyBZRX = totalSupplyByAsset(BZRX);
        uint256 totalSupplyVBZRX = totalSupplyByAsset(vBZRX);
        uint256 totalSupplyLPToken = totalSupplyByAsset(LPToken);
        
        uint256 totalTokens = totalSupplyBZRX
            .add(totalSupplyVBZRX)
            .add(totalSupplyLPToken);
            
        if (totalTokens == 0) {
            return (0, 0, 0);
        }

        uint256 multiplier = block.timestamp
            .sub(lastUpdateTime)
            .mul(normalizedRewardRate)
            .mul(1e18);

        bzrxReward = rewardsPerTokenStored[BZRX];
        if (totalSupplyBZRX != 0) {
            bzrxReward = bzrxReward.add(
                multiplier
                    .mul(totalSupplyBZRX)
                    .div(totalTokens)
            );
        }

        vbzrxReward = rewardsPerTokenStored[vBZRX];
        if (totalSupplyVBZRX != 0) {
            vbzrxReward = vbzrxReward.add(
                multiplier
                    .mul(totalSupplyVBZRX)
                    .div(totalTokens)
            );
        }

        lptokenReward = rewardsPerTokenStored[LPToken];
        if (totalSupplyLPToken != 0) {
            lptokenReward = lptokenReward.add(
                multiplier
                    .mul(totalSupplyLPToken)
                    .div(totalTokens)
            );
        }
    }

    function earned(
        address account)
        public
        view
        returns (uint256)
    {
        (uint256 bzrxReward,
         uint256 vbzrxReward,
         uint256 lptokenReward) = rewardsPerToken();
        
        return _earned(
            account,
            bzrxReward,
            vbzrxReward,
            lptokenReward
        );
    }

    function _earned(
        address account,
        uint256 bzrxReward,
        uint256 vbzrxReward,
        uint256 lptokenReward)
        internal
        view
        returns (uint256 earnedAmount)
    {
        uint256 bzrxBalance = balanceOfByAsset(BZRX, account);
        uint256 vbzrxBalance = balanceOfByAsset(vBZRX, account);
        
        // normalizes the LPToken balance
        uint256 lptokenBalance = _totalSupplyPerToken[LPToken];
        if (lptokenBalance != 0) {
            lptokenBalance = totalSupplyByAsset(LPToken)
                .mul(balanceOfByAsset(LPToken, account))
                .div(lptokenBalance);
        }

        uint256 totalTokens = bzrxBalance
            .add(vbzrxBalance);
        totalTokens = totalTokens
            .add(lptokenBalance);

        if (totalTokens == 0) {
            return 0;
        }

        uint256 remaining;

        remaining = bzrxReward
            .sub(userRewardPerTokenPaid[account][BZRX]);
        earnedAmount = bzrxBalance
            .mul(remaining);
        earnedAmount = earnedAmount
            .div(1e18);

        remaining = vbzrxReward
            .sub(userRewardPerTokenPaid[account][vBZRX]);
        earnedAmount = vbzrxBalance
            .mul(remaining)
            .div(1e18)
            .add(earnedAmount);

        remaining = lptokenReward
            .sub(userRewardPerTokenPaid[account][LPToken]);
        earnedAmount = lptokenBalance
            .mul(remaining)
            .div(1e18)
            .add(earnedAmount);

        earnedAmount = earnedAmount
            .mul(1e18)
            .div(totalTokens);

        earnedAmount = earnedAmount
            .add(rewards[account]);
    }


    function stakeableByAsset(
        address token,
        address account)
        public
        view
        returns (uint256)
    {
        uint256 walletBalance = IERC20(token).balanceOf(account);
        uint256 stakedBalance = balanceOfByAsset(
            token,
            account
        );

        return walletBalance > stakedBalance ?
            walletBalance - stakedBalance :
            0;
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256)
    {
        return _balancesPerToken[token][account];
        /*return _balanceOfByAsset(
            token,
            account,
            IERC20(token).balanceOf(account)
        );*/
    }

    function totalSupplyByAsset(
        address token)
        public
        view
        returns (uint256)
    {
        if (token == LPToken) {
            uint256 circulatingSupply = initialCirculatingSupply; // + VBZRX.totalVested();
            
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            return _totalSupplyPerToken[LPToken] != 0 ?
                circulatingSupply - _totalSupplyPerToken[BZRX] :
                0;
        } else {
            return _totalSupplyPerToken[token];
        }
    }

    function _setRepDelegate(
        address delegateToSet)
        internal
        returns (address currentDelegate)
    {
        currentDelegate = repDelegate[msg.sender];
        if (currentDelegate != ZERO_ADDRESS) {
            require(delegateToSet == ZERO_ADDRESS || delegateToSet == currentDelegate, "delegate already set");
        } else {
            if (delegateToSet == ZERO_ADDRESS) {
                delegateToSet = msg.sender;
            }
            repDelegate[msg.sender] = delegateToSet;

            emit DelegateChanged(
                msg.sender,
                currentDelegate,
                delegateToSet
            );

            currentDelegate = delegateToSet;
        }
    }

    /*function _balanceOfByAsset(
        address token,
        address account,
        uint256 walletBalance)
        internal
        view
        returns (uint256)
    {
        return _balancesPerToken[token][account].min256(walletBalance);
    }*/
}