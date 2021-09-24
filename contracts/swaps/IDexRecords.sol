pragma solidity 0.6.0;

interface IDexRecords {
    function retreiveDexAddress(uint256 dexNumber)
        external
        view
        returns (address);

    function setDexID(address dexAddress) external;
}
