// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "../interfaces/ICurvedInterestRate.sol";

contract CurvedInterestRate is ICurvedInterestRate {
    using PRBMathUD60x18 for uint256;

    uint256 public constant IR2 = 120e18;
    uint256 public constant UR1 = 80e18;
    uint256 public constant UR2 = 100e18;
    uint256 public constant UR_MAX = 100e18;
    uint256 public constant IR_MAX = 110e18;
    uint256 public constant IR_MIN = 0.1e18;

    function getInterestRate(
        uint256 _U,
        uint256 _a,
        uint256 _b
    ) public pure override returns (uint256 interestRate) {
        if (_U > UR_MAX) {
            _U = UR_MAX;
        }
        // general ae^(bx)
        return (_a * ((_b * _U) / 1e18).exp()) / 1e18;
    }

    function getAB(uint256 _IR1) public pure override returns (uint256 a, uint256 b) {
        return getAB(_IR1, IR2, UR1, UR2);
    }

    function getAB(
        uint256 _IR1,
        uint256 _IR2,
        uint256 _UR1,
        uint256 _UR2
    ) public pure override returns (uint256 a, uint256 b) {
        // some minimal interestRate to avoid zero a or b
        if (_IR1 < IR_MIN) {
            _IR1 = IR_MIN;
        }

        if (_IR1 > IR_MAX) {
            _IR1 = IR_MAX;
        }

        // b= math.log(1.2/0.2)/(0.9-0.8)
        // b = (ln((intRate2 * 1e18) / intRate1) * 1e18) / (utilRate2 - utilRate1);
        b = (((_IR2 * 1e18) / _IR1).ln() * 1e18) / (_UR2 - _UR1);
        // a = 0.2/e**(0.8 * b)
        a = (_IR1 * 1e18) / ((_UR1 * b) / 1e18).exp();
    }

    function calculateIR(uint256 _U, uint256 _IR1) public pure override returns (uint256 interestRate) {
        (uint256 a, uint256 b) = getAB(_IR1);
        return getInterestRate(_U, a, b);
    }
}
