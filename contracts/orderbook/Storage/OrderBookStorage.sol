pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../../interfaces/IToken.sol";
import "../../../interfaces/IBZx.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderBookStorage {
    address public constant WRAPPED_TOKEN =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uint256 public constant MIN_AMOUNT_IN_USDC = 1e6;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant vault = 0xFA6485ec4Aa9AF504adb4ed47b567E1875E21e85;
    IBZx public constant protocol = IBZx(0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8);

    mapping(bytes4 => address) public logicTargets;

    uint256 public mainOBID;

    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;
    }
}
