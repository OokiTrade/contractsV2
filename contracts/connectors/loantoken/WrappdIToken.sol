pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "@openzeppelin-2.5.0/token/ERC20/IERC20.sol";
import "../../../interfaces/IToken.sol"; 

contract WrappedIToken{
	uint256 public WEI_PRECISION = 10**20;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Mint(
        address indexed minter,
        uint256 tokenAmount
    );

    event Burn(
        address indexed burner,
        uint256 tokenAmount
    );
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
	address public LoanTokenAddress;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;
	
	constructor(string memory tname, string memory sym, uint8 dec, address LToken) public{
		name=tname;
		symbol=sym;
		decimals=dec;
		LoanTokenAddress=LToken;
		}
	
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }

	function TokenPrice() public view returns (uint256){
		return IToken(LoanTokenAddress).tokenPrice();
	}

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
	
	function balanceOf(address user) public view returns (uint256){
		return balances[user].mul(TokenPrice()).mul(100).div(WEI_PRECISION);
	}
	function _transfer(address from, address to, uint256 value) internal returns(bool){
		balances[from] = balances[from].sub(value);
		balances[to] = balances[to].add(value);
		emit Transfer(msg.sender,to,value);
		return true;
	}
    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function increaseApproval(
        address _spender,
        uint256 _addedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender]
            .add(_addedValue);
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender];
        if (_subtractedValue >= _allowed) {
            _allowed = 0;
        } else {
            _allowed -= _subtractedValue;
        }
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }
	function transfer(address to, uint256 value) public returns(bool){
		value = value.mul(WEI_PRECISION).div(TokenPrice()).div(100);
		return _transfer(msg.sender,to,value);

	}
	function transferFrom(address from, address to, uint256 value) public returns(bool){
		value = value.mul(WEI_PRECISION).div(TokenPrice()).div(100);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
		return _transfer(from,to,value);
	}
	function mint(
		address recv,
		uint256 depositAmount)
		public{
			IERC20(LoanTokenAddress).transferFrom(msg.sender,address(this),depositAmount);
			balances[recv] = balances[recv].add(depositAmount);
			totalSupply_ = totalSupply_.add(depositAmount);
			emit Mint(msg.sender,depositAmount);
			
		}
	function burn(
		address recv,
		uint256 burnAmount)
		public{
			if(burnAmount == uint256(-1)){
				burnAmount = balances[msg.sender];
				balances[msg.sender] = 0;
				IERC20(LoanTokenAddress).transfer(recv,burnAmount);
			}else{
				burnAmount = burnAmount.mul(WEI_PRECISION).div(TokenPrice()).div(100);
				balances[msg.sender] = balances[msg.sender].sub(burnAmount);
				IERC20(LoanTokenAddress).transfer(recv,burnAmount);
			}
			totalSupply_ = totalSupply_.sub(burnAmount);
			emit Burn(msg.sender,burnAmount);
		}
				
		
		
}