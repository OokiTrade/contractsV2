pragma solidity ^0.8.4;
interface TradeInterface{
	function swap(bytes calldata data) external;
}
contract trade{
	function swap(bytes calldata data) public{
		emit DataResponse(abi.decode(data, (uint)));
	}
	function runEncode(uint dd) public view returns(bytes memory){
		return abi.encode(dd);
	}
	event DataResponse(uint indexed resp);
}
contract router{

	struct DataArgs{
		address dexAddress;
		bytes dexData;
	}
	function executeRoute(bytes calldata dataArgs) public returns(uint){
		DataArgs[] memory routes = abi.decode(dataArgs, (DataArgs[]));
		for(uint i = 0;i<routes.length;i++){
			(bool success,) = (routes[i].dexAddress).delegatecall(abi.encodeWithSignature("swap(bytes)",routes[i].dexData));
			require(success);
		}
	
	}
	function encodeData(DataArgs[] calldata data) public view returns(bytes memory){
		return abi.encode(data);
	}
}