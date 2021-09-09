// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/cryptography/MerkleProof.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    mapping(uint256 => address) public override airdropToken;
    mapping(uint256 => uint256) public override airdropBalance;
    mapping(uint256 => bytes32) public override merkleRoot;
    mapping(uint256 => address) public override airdropSource;

    // This is a packed array of booleans per airdrop
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;
    uint256 public airdropCount;

    function createAirdrop(
        address token_,
        bytes32 merkleRoot_,
        address source_,
        uint256 amount_
    ) external override onlyOwner {
        if (source_ == address(this)) {
            require(IERC20(token_).transferFrom(msg.sender, address(this), amount_), "MerkleDistributor: Transfer failed.");
        }
        uint256 currentAirdropIndex = airdropCount;
        airdropToken[currentAirdropIndex] = token_;
        airdropBalance[currentAirdropIndex] = amount_;
        airdropSource[currentAirdropIndex] = source_;
        merkleRoot[currentAirdropIndex] = merkleRoot_;
        airdropCount++;
    }

    function isClaimed(uint256 airdropIndex, uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[airdropIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 airdropIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[airdropIndex][claimedWordIndex] = claimedBitMap[airdropIndex][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 airdropIndex,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(airdropIndex, index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot[airdropIndex], node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(airdropIndex, index);
        airdropBalance[airdropIndex] = sub(airdropBalance[airdropIndex], amount);

        address source = airdropSource[airdropIndex];
        if (source == address(this)) {
            require(IERC20(airdropToken[airdropIndex]).transfer(account, amount), "MerkleDistributor: Transfer failed.");
        } else {
            require(IERC20(airdropToken[airdropIndex]).transferFrom(source, account, amount), "MerkleDistributor: Transfer failed.");
        }

        emit Claimed(airdropIndex, index, account, amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 c) {
        require((c = x - y) <= x, "subtraction-overflow");
    }
}
