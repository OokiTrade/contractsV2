pragma solidity >=0.6.12;

import "../../../interfaces/IUniv3Twap.sol";

interface IFeedFactory is IUniv3Twap {
    function specs() external view returns (V3Specs memory);
}