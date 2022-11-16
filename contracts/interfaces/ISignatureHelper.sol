pragma solidity >=0.5.0 <0.6.0;

interface ISignatureHelper {
    function getSig(bytes calldata data) external pure returns (bytes4);
}