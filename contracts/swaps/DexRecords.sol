pragma solidity 0.5.17;

contract DexRecords {
    mapping(uint256 => address) public dexes;
    uint256 public dexCount = 0;

    function retrieveDexAddress(uint256 number) public view returns (address) {
        return dexes[number];
    }

    function setDexID(address dex) public {
        dexCount++;
        dexes[dexCount] = dex;
    }
}
