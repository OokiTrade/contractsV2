pragma solidity >=0.5.17 <0.9.0;

contract Flags {
    uint128 public constant DEX_SELECTOR_FLAG = 2; // base-2: 10
    uint128 public constant DELEGATE_FLAG = 4;
    uint128 public constant PAY_WITH_OOKI_FLAG = 8;
    uint128 public constant HOLD_OOKI_FLAG = 1;
}
