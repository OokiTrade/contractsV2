pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
contract safeTransfers{
    function _safeTransfer(address token,address to,uint256 amount,string memory error) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(IERC20Metadata(token).transfer.selector, to, amount),error);
    }

    function _safeTransferFrom(address token,address from,address to,uint256 amount,string memory error) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(IERC20Metadata(token).transferFrom.selector, from, to, amount),error);
    }

    function _callOptionalReturn(address token,bytes memory data,string memory error) internal {
        (bool success, bytes memory returndata) = token.call(data);
        require(success, error);
        if (returndata.length != 0) {
            require(abi.decode(returndata, (bool)), error);
        }
    }
}