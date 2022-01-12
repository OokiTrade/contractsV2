pragma solidity ^0.8.0;
import "./OrderBookInterface.sol";
import "./IUniswapV2Router.sol";
import "../WrappedToken.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderKeeper {
    address factory;
    address constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address swapAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    constructor(address factoryAddress) {
        factory = factoryAddress;
    }

    function checkUpkeep(bytes calldata checkData)
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        IOrderBook.OpenOrder[] memory listOfMainOrders = IOrderBook(factory)
            .getOrders();
        for (uint256 x = 0; x < listOfMainOrders.length; x++) {
            if (
                IOrderBook(factory).prelimCheck(
                    listOfMainOrders[x].orderID
                )
            ) {
                upkeepNeeded = true;
                performData = abi.encode(
                    listOfMainOrders[x].orderID
                );
                return (upkeepNeeded, performData);
            }
        }
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) public {
        (bytes32 orderId) = abi.decode(
            performData,
            (bytes32)
        );
        //emit OrderExecuted(trader,orderId);
        IOrderBook(factory).executeOrder(
            payable(address(this)),
            orderId
        );
    }

    /*function handleFees(address[] memory tokenAddress) public {
        address[] memory path;
        path = new address[](3);
        path[1] = WETH;
        path[2] = LINK;
        for (uint256 x = 0; x < tokenAddress.length; x++) {
            if (tokenAddress[x] != WETH) {
                path[0] = tokenAddress[x];
                uniswapV2Router(swapAddress).swapExactTokensForTokens(
                    IERC20Metadata(tokenAddress[x]).balanceOf(address(this)),
                    1,
                    path,
                    address(this),
                    block.timestamp
                );
            } else {
                address[] memory pathWETH;
                pathWETH = new address[](2);
                pathWETH[0] = WETH;
                pathWETH[1] = LINK;
                uniswapV2Router(swapAddress).swapExactTokensForTokens(
                    IERC20Metadata(tokenAddress[x]).balanceOf(address(this)),
                    1,
                    pathWETH,
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    function handleETHFees() public {
        WrappedToken(WETH).deposit{value: address(this).balance}();
    }*/
}
