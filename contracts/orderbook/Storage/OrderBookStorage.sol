pragma solidity ^0.8.4;

import "../WrappedToken.sol";
import "../bZxInterfaces/IPriceFeeds.sol";
import "../bZxInterfaces/ILoanToken.sol";
import "../bZxInterfaces/IBZX.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderBookStorage{
    address internal bZxRouterAddress = address(0);
    address internal walletGen;
    address internal constant wrapToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
	address internal smartWalletLogic;
	address internal constant UniFactoryContract = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
	uint internal mainOBID = 0;
}