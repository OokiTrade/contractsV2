pragma solidity ^0.8.4;
abstract contract IERC{
	uint8 public decimals;
    function totalSupply() public virtual view returns(uint);
    function balanceOf(address tOwner) public virtual view returns(uint balance);
    function allowance(address tOwner,address spender) public virtual view returns(uint reamining);
    function approve(address spender,uint amount) public virtual returns(bool success);
    function transfer(address to, uint amount) public virtual returns(bool success);
    function transferFrom(address from, address to, uint amount) public virtual returns(bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract WBNB{
	function deposit() public payable virtual;
}