/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */


pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";
// import "@openzeppelin-4.3.2/math/SafeMath";
contract TWAI {
    using PRBMathUD60x18 for uint256;
    // using SafeMath for uint256;

    event Logger(string name, uint256 value);
    // uint256 public twai;
    // uint256 public lastTimestamp;
    uint256 public lastIR;
    uint256 public a;
    uint256 public b;

    function writeIR(uint256 _lastIR) public {
        lastIR = _lastIR;
    }

    function borrow(uint256 newUtilization) public returns (uint256 interestRate) {
        (uint256 a, uint256 b) = getAB(lastIR);
        interestRate = getInterestRate(newUtilization, a, b);
        lastIR = interestRate;
    }
    
    function calculateIR(
        uint256 U,
        uint256 IR1,
        uint256 IR2,
        uint256 UR1,
        uint256 UR2
    ) public pure returns (uint256 interestRate) {
        (uint256 a, uint256 b) = getAB(IR1, IR2, UR1, UR2);
        return getInterestRate(U, a, b);
    }

    // this is supposed to be more efficient but its not because 2 reads and 2 writes every time. 
    // while borrow has a read + write + small calc. that small calc doesn't cover 1 read+ write
    function borrow2(uint256 newUtilization) public returns (uint256 interestRate) {
              
        interestRate = getInterestRate(newUtilization, a, b);

        (a , b) = getAB(interestRate);

    }

    function getAB(
        uint256 IR1,
        uint256 IR2,
        uint256 UR1,
        uint256 UR2
    ) public pure returns (uint256 a, uint256 b) {
        // some minimal interestRate to avoid zero a or b
        if (IR1 < 0.001e18) {
            IR1 = 0.001e18;
        }

        // b= math.log(1.2/0.2)/(0.9-0.8)
        // b = (ln((intRate2 * 1e18) / intRate1) * 1e18) / (utilRate2 - utilRate1);
        b = ((IR2 * 1e18) / IR1).ln() *1e18/ (UR2 - UR1);
        // a = 0.2/e**(0.8 * b)
        // uint256 temp;
        // emit Logger("(IR1 * 1e18) ", (IR1 * 1e18));
        // emit Logger("((UR2 * b) / 1e18).exp()", ((UR2 * b) / 1e18).exp());
        // emit Logger("(UR2 * b) / 1e18", (UR1 * b) / 1e18);

        a = (IR1 * 1e18) / ((UR1 * b) / 1e18).exp();
    }



    function getAB(uint256 interestRate) public pure returns (uint256 a, uint256 b) {
        // some minimal interestRate to avoid zero a or b
        if (interestRate < 0.001e18) {
            interestRate = 0.001e18;
        }

        // if (interestRate > 1e18) {
        //     interestRate = 1e18;
        // }
        uint256 utilRate1 = 0.8e18;
        uint256 utilRate2 = 1e18;
        uint256 intRate1 = interestRate;
        uint256 intRate2 = 1.2e18; // TODO this actually states that at 100% utilization we have 120 interest rate. I believe this should be 200%
        // y = (1000 * (((0.2/1.2) ** (1/1000)) - 1))/(0.8-0.9)
        // x = 0.2/e**(0.8 * y)

        // a = (1 - (1000 * (((intRate1*1e18/intRate2) ** (1/1000)) )/(utilRate2 - utilRate1);
        // b= math.log(1.2/0.2)/(0.9-0.8)
        b = (ln((intRate2 * 1e18) / intRate1) * 1e18) / (utilRate2 - utilRate1);
        // a = 0.2/e**(0.8 * b)
        // emit Logger("(IR1 * 1e18) ", (intRate1 * 1e18));
        // emit Logger("((UR2 * b) / 1e18).exp()", exp((utilRate1 * b) / 1e18));
        // emit Logger("(UR2 * b) / 1e18", (utilRate1 * b) / 1e18);
        a = (intRate1 * 1e18) / exp((utilRate1 * b) / 1e18);
    }

    function getCurrentInterestRateBasedOnCurrentCurve(uint256 newUtilization) public view returns (uint256 interestRate) {
        (uint256 a, uint256 b) = getAB(lastIR);
        return getInterestRate(newUtilization, a, b);
    }

    function getCurrentInterestRateBasedOnCurrentCurve2(uint256 newUtilization) public view returns (uint256 interestRate) {
        return getInterestRate(newUtilization, a, b);
    }


    function getInterestRate(
        uint256 utilization,
        uint256 a,
        uint256 b
    ) public pure returns (uint256 interestRate) {
        // (uint256 a, uint256 b) = getAB(interestRate);
        // if (utilization < 1e18) {
        //     utilization = 1e18;
        // }
        // return (a*e/1e18)**(b*interestRate/1e36);
        return (a * exp((b * utilization) / 1e18)) / 1e18;
    }



    uint256 internal constant SCALE = 1e18;
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
    uint256 internal constant HALF_SCALE = 5e17;
    uint256 internal constant LOG2_E = 1_442695040888963407;

    function log2(uint256 x) public pure returns (uint256 result) {
        if (x < SCALE) {
            // revert PRBMathUD60x18__LogInputTooSmall(x);
            require(true, "PRBMathUD60x18__LogInputTooSmall");
        }
        // unchecked {
        // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = mostSignificantBit(x / SCALE);

        // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
        // because n is maximum 255 and SCALE is 1e18.
        result = n * SCALE;

        // This is y = x * 2^(-n).
        uint256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == SCALE) {
            return result;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        // }
    }

    function mostSignificantBit(uint256 x) public pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    function exp(uint256 x) public pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            require(true, "PRBMathUD60x18__ExpInputTooBig");
            // revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        // unchecked {
        uint256 doubleScaleProduct = x * LOG2_E;
        result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        // }
    }

    function exp2(uint256 x) public pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            // revert PRBMathUD60x18__Exp2InputTooBig(x);
            require(true, "PRBMathUD60x18__Exp2InputTooBig");
        }

        // unchecked {
        // Convert x to the 192.64-bit fixed-point format.
        uint256 x192x64 = (x << 64) / SCALE;

        // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
        result = exp2PRBMath(x192x64);
        // }
    }

    function exp2PRBMath(uint256 x) public pure returns (uint256 result) {
        // unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0x8000000000000000 > 0) {
            result = (result * 0x16A09E667F3BCC909) >> 64;
        }
        if (x & 0x4000000000000000 > 0) {
            result = (result * 0x1306FE0A31B7152DF) >> 64;
        }
        if (x & 0x2000000000000000 > 0) {
            result = (result * 0x1172B83C7D517ADCE) >> 64;
        }
        if (x & 0x1000000000000000 > 0) {
            result = (result * 0x10B5586CF9890F62A) >> 64;
        }
        if (x & 0x800000000000000 > 0) {
            result = (result * 0x1059B0D31585743AE) >> 64;
        }
        if (x & 0x400000000000000 > 0) {
            result = (result * 0x102C9A3E778060EE7) >> 64;
        }
        if (x & 0x200000000000000 > 0) {
            result = (result * 0x10163DA9FB33356D8) >> 64;
        }
        if (x & 0x100000000000000 > 0) {
            result = (result * 0x100B1AFA5ABCBED61) >> 64;
        }
        if (x & 0x80000000000000 > 0) {
            result = (result * 0x10058C86DA1C09EA2) >> 64;
        }
        if (x & 0x40000000000000 > 0) {
            result = (result * 0x1002C605E2E8CEC50) >> 64;
        }
        if (x & 0x20000000000000 > 0) {
            result = (result * 0x100162F3904051FA1) >> 64;
        }
        if (x & 0x10000000000000 > 0) {
            result = (result * 0x1000B175EFFDC76BA) >> 64;
        }
        if (x & 0x8000000000000 > 0) {
            result = (result * 0x100058BA01FB9F96D) >> 64;
        }
        if (x & 0x4000000000000 > 0) {
            result = (result * 0x10002C5CC37DA9492) >> 64;
        }
        if (x & 0x2000000000000 > 0) {
            result = (result * 0x1000162E525EE0547) >> 64;
        }
        if (x & 0x1000000000000 > 0) {
            result = (result * 0x10000B17255775C04) >> 64;
        }
        if (x & 0x800000000000 > 0) {
            result = (result * 0x1000058B91B5BC9AE) >> 64;
        }
        if (x & 0x400000000000 > 0) {
            result = (result * 0x100002C5C89D5EC6D) >> 64;
        }
        if (x & 0x200000000000 > 0) {
            result = (result * 0x10000162E43F4F831) >> 64;
        }
        if (x & 0x100000000000 > 0) {
            result = (result * 0x100000B1721BCFC9A) >> 64;
        }
        if (x & 0x80000000000 > 0) {
            result = (result * 0x10000058B90CF1E6E) >> 64;
        }
        if (x & 0x40000000000 > 0) {
            result = (result * 0x1000002C5C863B73F) >> 64;
        }
        if (x & 0x20000000000 > 0) {
            result = (result * 0x100000162E430E5A2) >> 64;
        }
        if (x & 0x10000000000 > 0) {
            result = (result * 0x1000000B172183551) >> 64;
        }
        if (x & 0x8000000000 > 0) {
            result = (result * 0x100000058B90C0B49) >> 64;
        }
        if (x & 0x4000000000 > 0) {
            result = (result * 0x10000002C5C8601CC) >> 64;
        }
        if (x & 0x2000000000 > 0) {
            result = (result * 0x1000000162E42FFF0) >> 64;
        }
        if (x & 0x1000000000 > 0) {
            result = (result * 0x10000000B17217FBB) >> 64;
        }
        if (x & 0x800000000 > 0) {
            result = (result * 0x1000000058B90BFCE) >> 64;
        }
        if (x & 0x400000000 > 0) {
            result = (result * 0x100000002C5C85FE3) >> 64;
        }
        if (x & 0x200000000 > 0) {
            result = (result * 0x10000000162E42FF1) >> 64;
        }
        if (x & 0x100000000 > 0) {
            result = (result * 0x100000000B17217F8) >> 64;
        }
        if (x & 0x80000000 > 0) {
            result = (result * 0x10000000058B90BFC) >> 64;
        }
        if (x & 0x40000000 > 0) {
            result = (result * 0x1000000002C5C85FE) >> 64;
        }
        if (x & 0x20000000 > 0) {
            result = (result * 0x100000000162E42FF) >> 64;
        }
        if (x & 0x10000000 > 0) {
            result = (result * 0x1000000000B17217F) >> 64;
        }
        if (x & 0x8000000 > 0) {
            result = (result * 0x100000000058B90C0) >> 64;
        }
        if (x & 0x4000000 > 0) {
            result = (result * 0x10000000002C5C860) >> 64;
        }
        if (x & 0x2000000 > 0) {
            result = (result * 0x1000000000162E430) >> 64;
        }
        if (x & 0x1000000 > 0) {
            result = (result * 0x10000000000B17218) >> 64;
        }
        if (x & 0x800000 > 0) {
            result = (result * 0x1000000000058B90C) >> 64;
        }
        if (x & 0x400000 > 0) {
            result = (result * 0x100000000002C5C86) >> 64;
        }
        if (x & 0x200000 > 0) {
            result = (result * 0x10000000000162E43) >> 64;
        }
        if (x & 0x100000 > 0) {
            result = (result * 0x100000000000B1721) >> 64;
        }
        if (x & 0x80000 > 0) {
            result = (result * 0x10000000000058B91) >> 64;
        }
        if (x & 0x40000 > 0) {
            result = (result * 0x1000000000002C5C8) >> 64;
        }
        if (x & 0x20000 > 0) {
            result = (result * 0x100000000000162E4) >> 64;
        }
        if (x & 0x10000 > 0) {
            result = (result * 0x1000000000000B172) >> 64;
        }
        if (x & 0x8000 > 0) {
            result = (result * 0x100000000000058B9) >> 64;
        }
        if (x & 0x4000 > 0) {
            result = (result * 0x10000000000002C5D) >> 64;
        }
        if (x & 0x2000 > 0) {
            result = (result * 0x1000000000000162E) >> 64;
        }
        if (x & 0x1000 > 0) {
            result = (result * 0x10000000000000B17) >> 64;
        }
        if (x & 0x800 > 0) {
            result = (result * 0x1000000000000058C) >> 64;
        }
        if (x & 0x400 > 0) {
            result = (result * 0x100000000000002C6) >> 64;
        }
        if (x & 0x200 > 0) {
            result = (result * 0x10000000000000163) >> 64;
        }
        if (x & 0x100 > 0) {
            result = (result * 0x100000000000000B1) >> 64;
        }
        if (x & 0x80 > 0) {
            result = (result * 0x10000000000000059) >> 64;
        }
        if (x & 0x40 > 0) {
            result = (result * 0x1000000000000002C) >> 64;
        }
        if (x & 0x20 > 0) {
            result = (result * 0x10000000000000016) >> 64;
        }
        if (x & 0x10 > 0) {
            result = (result * 0x1000000000000000B) >> 64;
        }
        if (x & 0x8 > 0) {
            result = (result * 0x10000000000000006) >> 64;
        }
        if (x & 0x4 > 0) {
            result = (result * 0x10000000000000003) >> 64;
        }
        if (x & 0x2 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }
        if (x & 0x1 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= SCALE;
        result >>= (191 - (x >> 64));
        // }
    }

    function ln(uint256 x) public pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        // unchecked {
        result = (log2(x) * SCALE) / LOG2_E;
        // }
    }
}
