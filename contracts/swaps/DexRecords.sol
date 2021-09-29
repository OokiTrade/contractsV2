pragma solidity 0.6.0;

contract DexRecords {
    mapping(uint256 => address) public dexes;
    uint256 public dexCount = 0;

    function retrieveDexAddress(uint256 number) public returns (address) {
        return dexes[number];
    }

    function setDexID(address dex) public {
        dexCount++;
        dexes[dexCount] = dex;
    }
}
