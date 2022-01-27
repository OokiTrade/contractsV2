// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "../interfaces/ICurvedInterestRate.sol";

contract CurvedInterestRate is ICurvedInterestRate {
    using PRBMathUD60x18 for uint256;

    function getInterestRate(
        uint256 U,
        uint256 a,
        uint256 b
    ) public pure override returns (uint256 interestRate) {
        // general ae^(bx)
        return (a * ((b * U) / 1e18).exp()) / 1e18;
    }

    function getAB(
        uint256 IR1,
        uint256 IR2,
        uint256 UR1,
        uint256 UR2
    ) public pure override returns (uint256 a, uint256 b) {
        // some minimal interestRate to avoid zero a or b
        if (IR1 < 0.001e18) {
            IR1 = 0.001e18;
        }

        // b= math.log(1.2/0.2)/(0.9-0.8)
        // b = (ln((intRate2 * 1e18) / intRate1) * 1e18) / (utilRate2 - utilRate1);
        b = ((IR2 * 1e18) / IR1).ln() / (UR2 - UR1);
        // a = 0.2/e**(0.8 * b)
        a = (IR1 * 1e18) / ((UR2 * b) / 1e18).exp();
    }
}
