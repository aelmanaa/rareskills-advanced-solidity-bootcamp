// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week2/2.ecosystem2/PrimeNFTCounter.sol";
import "../../../src/week2/2.ecosystem2/NFTCollection.sol";

contract PrimeNFTCounterTest is Test {
    PrimeNFTCounter private primeNFTCounter;
    NFTCollection private nftCollection;
    address private owner;
    address private user1;
    address private user2;

    function setUp() public {
        owner = address(this);
        user1 = address(1);
        user2 = address(2);

        nftCollection = new NFTCollection();
        primeNFTCounter = new PrimeNFTCounter(address(nftCollection));

        // transfer some NFTs to user1 - 2 primes
        nftCollection.transferFrom(owner, user1, 1);
        nftCollection.transferFrom(owner, user1, 2);
        nftCollection.transferFrom(owner, user1, 3);
        nftCollection.transferFrom(owner, user1, 4);
        nftCollection.transferFrom(owner, user1, 5);

        // transfer some NFTs to user2 - 1 prime
        nftCollection.transferFrom(owner, user2, 6);
        nftCollection.transferFrom(owner, user2, 7);
        nftCollection.transferFrom(owner, user2, 8);
        nftCollection.transferFrom(owner, user2, 9);
        nftCollection.transferFrom(owner, user2, 10);

        // owner has 11,12,13,14,15,16,17,18,19,20 left - 4 primes
    }

    function testCountPrimesOwnedBy() public {
        uint256 count = primeNFTCounter.countPrimesOwnedBy(user1);

        assertEq(count, 3);

        count = primeNFTCounter.countPrimesOwnedBy(user2);
        assertEq(count, 1);

        count = primeNFTCounter.countPrimesOwnedBy(owner);
        assertEq(count, 4);
    }
}
