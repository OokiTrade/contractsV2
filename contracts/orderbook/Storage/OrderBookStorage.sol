pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../../interfaces/IToken.sol";
import "../../../interfaces/IBZx.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderBookStorage {
    address public constant WRAPPED_TOKEN =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    uint256 public constant MIN_AMOUNT_IN_USDC = 1e6;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    mapping(bytes4 => address) public logicTargets;
    address public vault;
    IBZx public protocol;
    uint256 public mainOBID;

    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;
    }
}
