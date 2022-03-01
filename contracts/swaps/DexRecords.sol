pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract DexRecords is Ownable {
    mapping(uint256 => address) public dexes;
    uint256 public dexCount = 0;

    function retrieveDexAddress(uint256 number) public view returns (address) {
        return dexes[number];
    }

    function setDexID(address dex) public onlyOwner {
        dexCount++;
        dexes[dexCount] = dex;
    }

    function setDexID(uint256 ID, address dex) public onlyOwner {
        dexes[ID] = dex;
    }
	
    function getDexCount() external view returns(uint256) {
        return dexCount;
    }
}
