pragma solidity ^0.5.17;

interface IDexRecords {
    function retreiveDexAddress(uint256 dexNumber)
        external
        view
        returns (address);

    function setDexID(address dexAddress) external;
}
