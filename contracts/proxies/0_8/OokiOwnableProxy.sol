// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";

contract OokiOwnableProxy is Ownable, ERC1967Proxy {

    fallback() override payable external {
        require(msg.value == 0);
        _fallback();
    }

    constructor(
        address _logic,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {}

    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);
    }
}
