/// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "../interfaces/ICurvedInterestRate.sol";
import "../governance/PausableGuardian_0_8.sol";

contract CurvedInterestRate is PausableGuardian_0_8, ICurvedInterestRate {
    using PRBMathUD60x18 for uint256;

    // uint256 public constant IR2 = 120e18;
    // uint256 public constant UR1 = 80e18;
    // uint256 public constant UR2 = 100e18;
    // uint256 public constant UR_MAX = 100e18;
    // uint256 public constant IR_MAX = 110e18;
    // uint256 public constant IR_MIN = 0.1e18;
    // uint256 public constant IR_ABSOLUTE_MIN = 1e11;

    struct CurveIRParams {
        uint256 IR2;
        uint256 UR1;
        uint256 UR2;
        uint256 UR_MAX;
        uint256 IR_MAX;
        uint256 IR_MIN;
        uint256 IR_ABSOLUTE_MIN;
    }

    mapping(address => CurveIRParams) public PARAMS;

    function getInterestRate(
        uint256 _U,
        uint256 _a,
        uint256 _b,
        uint256 _UR_MAX,
        uint256 _IR_ABSOLUTE_MIN
    ) public pure override returns (uint256 interestRate) {
        if (_U > _UR_MAX) {
            _U = _UR_MAX;
        }
        // general ae^(bx)
        interestRate = (_a * ((_b * _U) / 1e18).exp()) / 1e18;
        if (interestRate < _IR_ABSOLUTE_MIN) {
            interestRate = _IR_ABSOLUTE_MIN;
        }
        return interestRate;
    }

    // function getAB(uint256 _IR1, address _OWNER) public pure override returns (uint256 a, uint256 b) {
    //     return getAB(_IR1, PARAMS[_OWNER].IR2, PARAMS[_OWNER].UR1, PARAMS[_OWNER].UR2);
    // }

    function getAB(
        uint256 _IR1,
        uint256 _IR2,
        uint256 _UR1,
        uint256 _UR2,
        uint256 _IR_MIN,
        uint256 _IR_MAX
    ) public pure override returns (uint256 a, uint256 b) {
        // some minimal interestRate to avoid zero a or b
        if (_IR1 < _IR_MIN) {
            _IR1 = _IR_MIN;
        } else if (_IR1 > _IR_MAX) {
            _IR1 = _IR_MAX;
        }

        // b= math.log(1.2/0.2)/(0.9-0.8)
        // b = (ln((intRate2 * 1e18) / intRate1) * 1e18) / (utilRate2 - utilRate1);
        b = (((_IR2 * 1e18) / _IR1).ln() * 1e18) / (_UR2 - _UR1);
        // a = 0.2/e**(0.8 * b)
        a = (_IR1 * 1e18) / ((_UR1 * b) / 1e18).exp();
    }

    function calculateIR(uint256 _U, uint256 _IR1) public view override returns (uint256 interestRate) {
        CurveIRParams memory localParam = PARAMS[msg.sender];

        if (localParam.IR_ABSOLUTE_MIN == 0) {
            // those will be the defaults
            localParam = PARAMS[address(0)];
        }

        (uint256 a, uint256 b) = getAB(_IR1, localParam.IR2, localParam.UR1, localParam.UR2, localParam.IR_MIN, localParam.IR_MAX);
        return getInterestRate(_U, a, b, localParam.UR_MAX, localParam.IR_ABSOLUTE_MIN);
    }

    function updateParams(CurveIRParams calldata _curveIRParams, address owner) public onlyGuardian {
        PARAMS[owner] = _curveIRParams;
    }
}
