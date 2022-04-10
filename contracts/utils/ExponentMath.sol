pragma solidity ^0.8.0;


library ExponentMath{

	function tenExp(uint256 number, int8 pow) public pure returns (uint256){
		if(pow < 0){
			number=number/10**(uint8(pow*-1));
		}else{
			number=number*10**uint8(pow);
		}
		return number;
	}

}