pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC721/ERC721.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "@openzeppelin-4.3.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin-4.3.2/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin-4.3.2/utils/math/SafeMath.sol";
import "@openzeppelin-4.3.2/utils/Counters.sol";

contract OokiCollection is ERC721, Ownable, ERC721Enumerable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _currentId;
    uint256 public startStamp;
    uint256 public constant COLLECTION_SIZE = 888;
    uint256 public constant PRICE = 0.17e18;
    uint256 public constant MAX_MINT = 20;
    address public constant CREATOR = 0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc;  //TREASURY
    string public baseTokenURI;

    event MintOOKINft(uint256 indexed id);

    constructor(string memory baseURI) ERC721("OOKI", "OOKI") {
        setBaseURI(baseURI);
        pause(true);
    }

    function setStartStamp(uint256 _startStamp) public onlyOwner {
        startStamp = _startStamp;
    }

    modifier saleIsOpen {
        require(_totalSupply() <= COLLECTION_SIZE, "All minted");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _currentId.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(startStamp > 0 && block.timestamp > startStamp, "Not started yet");
        require(total + _count <= COLLECTION_SIZE, "Max limit reached");
        require(total <= COLLECTION_SIZE, "All minted");
        require(_count <= MAX_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mint(_to);
        }
    }
    function _mint(address _to) private {
        uint id = _totalSupply();
        _currentId.increment();
        id = _currentId.current();
        _safeMint(_to, id);
        emit MintOOKINft(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(CREATOR, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}