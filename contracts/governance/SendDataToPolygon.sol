pragma solidity ^0.8.0;

import "../proxies/0_8/Upgradeable_0_8.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract SendDataToPolygon is Upgradeable_0_8{
	IFxStateSender public constant FxRoot = IFxStateSender(0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA);
	address public fxChildTunnel;
	
	function setFxChildTunnel(address tunnel) public onlyOwner{
		fxChildTunnel=tunnel;
	}
	
	function sendMessageToChild(bytes memory data) public onlyOwner{
		FxRoot.sendMessageToChild(fxChildTunnel,data);
	}
	
}