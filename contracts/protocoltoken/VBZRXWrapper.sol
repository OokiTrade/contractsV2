/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/SafeMath.sol";
import "../interfaces/IVestingToken.sol";


contract VBZRXWrapper {
    using SafeMath for uint256;

    // --- ERC20 Data ---
    string  public constant name     = "Wrapped vBZRX";
    string  public constant symbol   = "wvBZRX";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);
    IVestingToken public constant vBZRX = IVestingToken(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);

    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public bzrxPerTokenStored;
    mapping(address => uint256) public bzrxVestiesPerTokenPaid;
    mapping(address => uint256) public bzrxVesties;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed src, address indexed dst, uint256 value);
    event Deposit(address indexed dst, uint256 value);
    event Withdrawal(address indexed src, uint256 value);
    event Claim(address indexed owner, uint256 value);

    // --- Token ---
    function transfer(address dst, uint256 value) external returns (bool) {
        return transferFrom(msg.sender, dst, value);
    }

    function transferFrom(address src, address dst, uint256 value) public returns (bool) {
        require(balanceOf[src] >= value, "vBZRXWrapper/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= value, "vBZRXWrapper/insufficient-allowance");
            allowance[src][msg.sender] -= value;
        }
        balanceOf[src] -= value;
        balanceOf[dst] += value;
        emit Transfer(src, dst, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // --- Custom Logic ---

    modifier settleVesting {
        uint256 _bzrxPerTokenStored = bzrxPerTokenStored;
        uint256 _totalSupply = totalSupply;
        if (_totalSupply != 0) {
            uint256 balanceBefore = BZRX.balanceOf(address(this));
            
            vBZRX.claim();

            _bzrxPerTokenStored = BZRX.balanceOf(address(this))
                .sub(balanceBefore)
                .mul(1e36)
                .div(_totalSupply)
                .add(_bzrxPerTokenStored);
        }

        bzrxVesties[msg.sender] = _claimable(
            msg.sender,
            _bzrxPerTokenStored
        );
        bzrxPerTokenStored = _bzrxPerTokenStored;
        bzrxVestiesPerTokenPaid[msg.sender] = _bzrxPerTokenStored;

        _;
    }

    function _claimable(address account, uint256 _bzrxPerToken) internal view returns (uint256 bzrxVestiesClaimable) {
        uint256 bzrxPerTokenUnpaid = _bzrxPerToken.sub(bzrxVestiesPerTokenPaid[account]);
        bzrxVestiesClaimable = bzrxVesties[account];
        if (bzrxPerTokenUnpaid != 0) {
            bzrxVestiesClaimable = balanceOf[account]
                .mul(bzrxPerTokenUnpaid)
                .div(1e36)
                .add(bzrxVestiesClaimable);
        }
    }

    function _claim() internal returns (uint256 claimed) {
        claimed = bzrxVesties[msg.sender];
        if (claimed != 0) {
            bzrxVesties[msg.sender] = 0;
            BZRX.transfer(msg.sender, claimed);
        }
        emit Claim(msg.sender, claimed);
    }

    function claimable(address account) external view returns (uint256) {
        return _claimable(
            account,
            vBZRX.vestedBalanceOf(address(this))
                .mul(1e36)
                .div(totalSupply)
                .add(bzrxPerTokenStored)
        );
    }

    function claim() external settleVesting returns (uint256) {
        return _claim();
    }

    function exit() external {
        withdraw(uint256(-1));
        _claim();
    }

    function deposit(uint256 value) external settleVesting {
        vBZRX.transferFrom(msg.sender, address(this), value);
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit Transfer(address(0), msg.sender, value);
        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) public settleVesting {
        uint256 balance = balanceOf[msg.sender];
        if (value > balance) {
            value = balance;
        }
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        vBZRX.transfer(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        emit Withdrawal(msg.sender, value);
    }
}
