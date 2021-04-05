pragma solidity 0.8.0;

/// SPDX-License-Identifier: MIT

// import "@openzeppelin-v4.0.0/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin-v4.0.0/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-v4.0.0/access/Ownable.sol";

contract Proxy1 is TransparentUpgradeableProxy, Ownable {
    constructor(address _logic, address _admin)
        public
        TransparentUpgradeableProxy(_logic, _admin, "")
    {}
}
