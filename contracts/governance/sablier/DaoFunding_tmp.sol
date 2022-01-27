/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "../../farm/interfaces/Upgradeable.sol";


// Temporary implementation to handle initial monthly salaries, while full implementation is under development

// mainnet proxy: 0x37cBA8d1308019594621438bd1527E5A6a34B49F
contract DaoFunding_tmp is Upgradeable {
    function tmp_funding_transfer(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        _token.transfer(_to, _amount);
    }
    function tmp_funding_transferFrom(IERC20 _token, address _from, address _to, uint256 _amount) public onlyOwner {
        _token.transferFrom(_from, _to, _amount);
    }
}
