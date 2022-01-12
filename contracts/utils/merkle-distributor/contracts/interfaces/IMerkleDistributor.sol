// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {

    // Returns the address of the token distributed by this contract.
    function airdropToken(uint256 airdropIndex) external view returns (address);

    // Returns the merkle airdrop source 
    function airdropSource(uint256 airdropIndex) external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot(uint256 airdropIndex) external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 airdropIndex, uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 airdropIndex, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // create new aridrop
    function createAirdrop(address token, bytes32 merkleRoot, address airdropSource, uint256 amount) external;

    // This event is triggered whenever a new airdrop is created.
    event Created(uint256 indexed airdropIndex, address indexed token, address indexed source, uint256 amount);

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 indexed airdropIndex, address indexed token, address indexed account, uint256 index, uint256 amount);

    // This event is triggered whenever a call to #adminClaim succeeds. For owner only
    event AdminClaimed(uint256 indexed airdropIndex, address indexed token, address indexed account, uint256 index, uint256 amount);

    // This event is triggered whenever a call to #directClaim succeeds. For owner only
    event DirectClaimed(uint256 indexed airdropIndex, address indexed token, address indexed account, uint256 amount);
}
