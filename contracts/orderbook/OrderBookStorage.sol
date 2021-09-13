pragma solidity ^0.8.4;

contract OrderBookStorage{
    address internal bZxRouterAddress = address(0);
    address internal walletGen;
    address internal constant BNBAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
	address internal owner;
	address internal smartWalletLogic;
	address internal constant UniFactoryContract = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
	uint internal mainOBID = 0;
}