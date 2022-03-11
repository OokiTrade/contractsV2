/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "@openzeppelin-3.4.0/math/SafeMath.sol";

interface GovTokenLike {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
    function rescue(IERC20 token) external;
    function totalSupply() external returns (uint256);
}

// polygon: 0x52fb1688B829BDb2BF70058f0BBfFD38af26cc2b
// polygon (old): 0x21baFa16512D6B318Cca8Ad579bfF04f7b7D3440
contract MintCoordinator_Polygon is Ownable {
    using SafeMath for uint256;

    GovTokenLike public constant govToken = GovTokenLike(0xd5d84e75f48E75f01fb2EB6dFD8eA148eE3d0FEb);
    mapping (address => bool) public minters;
    
    // we store totalMinted here instead of using pure IERC20.totalSupply because burn removes from totalSupply.
    uint256 public totalMinted;

    uint256 public constant MAX_MINTED = 250*1e6*1e18;

    constructor() public {
        // adding MasterChef
        minters[0xd39Ff512C3e55373a30E94BB1398651420Ae1D43] = true;
    }

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");

        uint256 _totalMinted = totalMinted;
        if (_totalMinted >= MAX_MINTED) {
            // we're done minting
            return;
        }
        if (_totalMinted.add(_amount) >= MAX_MINTED) {
            _amount = MAX_MINTED.sub(_totalMinted);
        }

        govToken.mint(_to, _amount);
        if (_totalMinted == 0) {
            // this condition executes once
            _totalMinted = govToken.totalSupply();
        } else {
            _totalMinted = _totalMinted.add(_amount); // better safe than sorry
        }
        totalMinted = _totalMinted;
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        govToken.transferOwnership(newOwner);
    }

    function addMinter(address addr) public onlyOwner {
        minters[addr] = true;
    }

    function removeMinter(address addr) public onlyOwner {
        minters[addr] = false;
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function rescueToken(IERC20 _token) public onlyOwner {
        govToken.rescue(_token);
        rescue(_token);
    }
}
