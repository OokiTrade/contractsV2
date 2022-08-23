pragma solidity ^0.8.0;

import "@openzeppelin-4.7.0/interfaces/IERC4626.sol";

interface IVault is IERC4626 {

    //Used to claim any accrued rewards and is converted into the underlying asset increasing value of each share
    function compound() external;



}