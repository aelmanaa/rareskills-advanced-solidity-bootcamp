// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week2/2.ecosystem2/PrimeChecker.sol";

contract PrimeCheckerTest is Test {
    mapping(uint256 => bool) somePrimes;

    function setUp() public {
        somePrimes[2] = true;
        somePrimes[3] = true;
        somePrimes[5] = true;
        somePrimes[7] = true;
        somePrimes[11] = true;
        somePrimes[13] = true;
        somePrimes[17] = true;
        somePrimes[19] = true;
        somePrimes[23] = true;
        somePrimes[29] = true;
        somePrimes[31] = true;
        somePrimes[37] = true;
        somePrimes[41] = true;
        somePrimes[43] = true;
        somePrimes[47] = true;
        somePrimes[53] = true;
        somePrimes[59] = true;
        somePrimes[61] = true;
        somePrimes[67] = true;
        somePrimes[71] = true;
        somePrimes[73] = true;
        somePrimes[79] = true;
        somePrimes[83] = true;
        somePrimes[89] = true;
        somePrimes[97] = true;
        somePrimes[101] = true;
        somePrimes[103] = true;
        somePrimes[107] = true;
        somePrimes[109] = true;
        somePrimes[113] = true;
        somePrimes[127] = true;
        somePrimes[131] = true;
        somePrimes[137] = true;
        somePrimes[139] = true;
        somePrimes[149] = true;
        somePrimes[151] = true;
        somePrimes[157] = true;
        somePrimes[163] = true;
        somePrimes[167] = true;
        somePrimes[173] = true;
        somePrimes[179] = true;
        somePrimes[181] = true;
        somePrimes[191] = true;
        somePrimes[193] = true;
        somePrimes[197] = true;
        somePrimes[199] = true;
        somePrimes[211] = true;
        somePrimes[223] = true;
        somePrimes[227] = true;
        somePrimes[229] = true;
        somePrimes[233] = true;
        somePrimes[239] = true;
        somePrimes[241] = true;
        somePrimes[251] = true;
    }

    function testPrime(uint8 number) public {
        if (somePrimes[number]) {
            assertTrue(PrimeChecker.isPrime(number), "Number should be prime");
        } else {
            assertFalse(
                PrimeChecker.isPrime(number),
                "Number should not be prime"
            );
        }
    }

    function testOnePrime() public {
        assertTrue(PrimeChecker.isPrime(251), "Number should be prime");
        assertFalse(PrimeChecker.isPrime(256), "Number should not be prime");
    }
}
