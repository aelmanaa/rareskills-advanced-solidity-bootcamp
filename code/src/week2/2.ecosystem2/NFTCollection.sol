// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title NFTCollection
 * @dev A simple ERC721Enumerable NFT collection.
 * @notice This contract mints a collection of 20 unique NFTs upon deployment.
 *         The NFTs have token IDs ranging from 1 to 20.
 */
contract NFTCollection is ERC721Enumerable {
    /**
     * @notice Constructs the NFTCollection contract and mints 20 NFTs to the deployer.
     * @dev Mints 20 NFTs with token IDs from 1 to 20 to the address deploying the contract.
     */
    constructor() ERC721("NFTCollection", "MNFT") {
        for (uint i = 1; i <= 20; i++) {
            _mint(msg.sender, i);
        }
    }
}
