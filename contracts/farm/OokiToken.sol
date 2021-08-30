// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";


contract OokiToken is ERC20, Ownable {
    constructor() ERC20("Ooki Token", "OOKI") public {}

    uint256 public totalMinted;
    uint256 public totalBurned;

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        totalMinted = totalMinted.add(_amount);
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
        totalBurned = totalBurned.add(_amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }
}
