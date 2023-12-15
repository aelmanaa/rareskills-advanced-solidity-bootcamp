// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library PrimeChecker {
    /**
     * @notice Checks if a number is prime.
     * @dev Determines primality of a given number. A number is prime if it is greater than 1 and has no divisors other than 1 and itself.
     *      Uses an optimized approach by checking divisibility up to the square root of the number.
     * @param number The number to check for primality.
     * @return True if the number is a prime, false otherwise.
     */
    function isPrime(uint256 number) internal pure returns (bool) {
        unchecked {
            if (number < 2) return false;
            for (uint i = 2; i * i <= number; i++) {
                if (number % i == 0) return false;
            }
            return true;
        }
    }
}
