// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week2/1.ecosystem1/NFT.sol";

contract NFTTest is Test {
    NFT public nft;
    address public user1 = address(0x1);
    address public user2 = address(0x99);

    function setUp() public {
        bytes32 merkleRoot = 0xf15a55a831383766d4538f27ed136da17dacc03e017cc20ae8bd4e45273585b0;
        uint256 discount = 15; // 15%
        uint256 initialPrice = 1.5 ether;
        nft = new NFT(merkleRoot, discount, initialPrice);
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 2 ether);
    }

    function testMintDiscount() public {
        bytes32[] memory proof = new bytes32[](3);
        proof[
            0
        ] = 0x03f486a77b3b3edefdec5153a0de58083e0d2832315cf21a981052c1b9bbd0eb;
        proof[
            1
        ] = 0xd17d067069f7eff1ce10ea18d339a850e7b4a13986aabec274eb72d5068d630d;
        proof[
            2
        ] = 0x2546731f1d06accc4944db41c8f15f75f255c35435a76059b5887452b072950b;

        uint256 index = 0;
        uint256 amount = 10;
        uint256 discountedPrice = nft.getDiscountedPrice(amount);

        assertEq(nft.balanceOf(user1), 0);

        vm.prank(user1);
        nft.mintDiscount{value: discountedPrice}(proof, index, amount, user1);

        assertEq(nft.balanceOf(user1), amount);
    }

    function testMint() public {
        //anyone can mint 1 token at a normal price

        uint256 pricePerToken = nft.initialPrice();

        assertEq(nft.balanceOf(user2), 0);

        vm.prank(user2);
        nft.mint{value: pricePerToken}(user2);

        assertEq(nft.balanceOf(user2), 1);
    }
}
