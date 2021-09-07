// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/cryptography/MerkleProof.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    mapping(uint256 => address) public override token;
    mapping(uint256 => bytes32) public override merkleRoot;
    mapping(uint256 => address) public override airdropSource;

    // This is a packed array of booleans per airdrop
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;
    uint256 public airdropCount;

    address public constant STAKING = 0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4;

    function createAirdrop(
        address token_,
        bytes32 merkleRoot_,
        address airdropSource_,
        uint256 amount_
    ) external override onlyOwner {
        require(IERC20(token_).transferFrom(msg.sender, address(this), amount_), "MerkleDistributor: Transfer failed.");
        uint256 currentAirdropIndex = airdropCount;
        token[currentAirdropIndex] = token_;
        merkleRoot[currentAirdropIndex] = merkleRoot_;
        airdropSource[currentAirdropIndex] = airdropSource_;
        airdropCount += 1;
    }

    function setApproval(
        address token_,
        address spender_,
        uint256 value_)
        external
        onlyOwner
    {
        IERC20(token_).approve(spender_, value_);
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
        require(IERC20(token[airdropIndex]).transferFrom(airdropSource[airdropIndex], account, amount), "MerkleDistributor: Transfer failed.");

        emit Claimed(airdropIndex, index, account, amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }
}
