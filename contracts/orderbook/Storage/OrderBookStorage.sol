pragma solidity ^0.8.0;

import "../WrappedToken.sol";
import "../../../interfaces/IPriceFeeds.sol";
import "../../../interfaces/IToken.sol";
import "../../../interfaces/IBZX.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderBookStorage {
    mapping(bytes4 => address) public logicTargets;
    address public vault = address(0);
    address public protocol = address(0);
    address public constant WRAPPED_TOKEN =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant UNI_FACTORY =
        0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    uint256 public mainOBID = 0;
    uint256 public DAYS_14 = 86400 * 14;
    uint256 public MIN_AMOUNT_IN_USDC = 1 * 10**15;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;
    }
}
