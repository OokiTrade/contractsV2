/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../governance/PausableGuardian.sol";


contract ProtocolPausableGuardian is State, PausableGuardian {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this._isPaused.selector, target);
        _setTarget(this.toggleFunctionPause.selector, target);
        _setTarget(this.toggleFunctionUnPause.selector, target);
        _setTarget(this.pause.selector, target);
        _setTarget(this.unpause.selector, target);
        _setTarget(this.changeGuardian.selector, target);
        _setTarget(this.getGuardian.selector, target);
    }

    function pause(bytes4 [] calldata sig)
        external
        onlyGuardian

    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionPause(sig[i]);
        }
    }

    function unpause(bytes4 [] calldata sig)
        external
        onlyGuardian
    {
        for(uint256 i = 0; i < sig.length; ++i){
            toggleFunctionUnPause(sig[i]);
        }
    }
}
