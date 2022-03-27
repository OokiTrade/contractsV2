pragma solidity >=0.5.17;

interface IDexRecords {
    function retrieveDexAddress(uint256 dexNumber)
        external
        view
        returns (address);

    function setDexID(address dexAddress) external;
	
    function setDexID(uint256 dexID, address dexAddress) external;
	
    function getDexCount() external view returns(uint256);
}
