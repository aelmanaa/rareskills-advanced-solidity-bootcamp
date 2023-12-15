// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./NFTCollection.sol";
import "./PrimeChecker.sol";

/**
 * @title PrimeNFTCounter
 * @dev A contract to count the number of prime number token IDs owned by a given address in an NFT collection.
 * @notice This contract works with an NFT collection and identifies how many NFTs owned by an address have prime number token IDs.
 */
contract PrimeNFTCounter {
    using PrimeChecker for uint256;
    NFTCollection public nftCollection;

    /**
     * @notice Creates a PrimeNFTCounter for a given NFT collection.
     * @param _nftCollectionAddress Address of the NFT collection contract to be analyzed.
     */
    constructor(address _nftCollectionAddress) {
        nftCollection = NFTCollection(_nftCollectionAddress);
    }

    /**
     * @notice Counts how many NFTs owned by a specific address have prime number token IDs.
     * @param owner Address whose NFTs are to be analyzed.
     * @return primeCount The number of NFTs with prime number token IDs owned by the address.
     * @dev Iterates through all the NFTs owned by the provided address and checks if their token IDs are prime numbers.
     */
    function countPrimesOwnedBy(
        address owner
    ) public view returns (uint256 primeCount) {
        uint256 balance = nftCollection.balanceOf(owner);
        uint256 tokenId;
        unchecked {
            for (uint256 i = 0; i < balance; i++) {
                tokenId = nftCollection.tokenOfOwnerByIndex(owner, i);
                if (tokenId.isPrime()) {
                    primeCount++;
                }
            }
        }
    }
}
