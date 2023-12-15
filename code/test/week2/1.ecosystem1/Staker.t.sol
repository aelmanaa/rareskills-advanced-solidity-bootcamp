// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week2/1.ecosystem1/Staker.sol";
import "../../../src/week2/1.ecosystem1/NFT.sol";
import "../../../src/week2/1.ecosystem1/RewardToken.sol";

contract RewardTokenTest is Test {
    Staker public staker;
    RewardToken public rewardToken;
    NFT public nft;

    address owner;
    address user1 = address(0x123);
    address user2 = address(0x1);

    uint256 rewards;

    function setUp() public {
        owner = address(this);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        rewardToken = new RewardToken();
        bytes32 merkleRoot = 0xf15a55a831383766d4538f27ed136da17dacc03e017cc20ae8bd4e45273585b0;
        uint256 discount = 15; // 15%
        uint256 initialPrice = 1.5 ether;
        nft = new NFT(merkleRoot, discount, initialPrice);
        staker = new Staker(rewardToken, nft);

        rewardToken.transferOwnership(address(staker));
        staker.acceptTokenOwnership();

        rewards = staker.rewards();
    }

    function testStake() public {
        // Setup: Mint NFT to user1
        uint256 pricePerToken = nft.initialPrice();
        vm.startPrank(user1);
        nft.mint{value: pricePerToken}(user1);
        nft.approve(address(staker), 0);

        // Action: Stake NFT
        staker.stake(0);

        // Check: NFT staked
        assertEq(nft.ownerOf(0), address(staker));

        nft.mint{value: pricePerToken}(user1);
        nft.safeTransferFrom(user1, address(staker), 1);
        assertEq(nft.ownerOf(1), address(staker));
        vm.stopPrank();
        (uint256 amount, ) = staker.userInfo(user1);
        assertEq(amount, 2);
    }

    function testClaimReward() public {
        // Setup: Stake NFT
        testStake();

        // Action: Claim reward
        vm.warp(block.timestamp + 3 days);
        vm.startPrank(user1);
        staker.claimReward(user1);
        vm.stopPrank();

        // Check: Rewards claimed
        uint256 expectedRewards = 3 * 2 * rewards; // there are 2 tokens and 3 days have passed
        assertEq(rewardToken.balanceOf(user1), expectedRewards);
    }

    function testWithdraw() public {
        // Setup: Stake NFT
        testStake();

        // Action: Withdraw NFT
        vm.startPrank(user1);
        staker.withdraw(1, user1);
        vm.stopPrank();

        // Check: NFT withdrawn
        assertEq(nft.ownerOf(1), user1);
    }

    function testTwoUsers() public {
        testStake(); // user1 staked 2 tokens

        vm.warp(block.timestamp + 3 days); // 3 days passed

        vm.startPrank(user2);
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

        assertEq(nft.balanceOf(user2), 0);

        nft.mintDiscount{value: discountedPrice}(proof, index, amount, user2);

        assertEq(nft.balanceOf(user2), amount);
        for (uint256 i = 2; i < 12; i++) {
            nft.safeTransferFrom(user2, address(staker), i);
        }

        (uint256 numberTokens, uint256 rewardDebt) = staker.userInfo(user2);
        assertEq(numberTokens, 10);
        assertEq(rewardDebt, 10 * staker.accumulatorRewardPerNFT());

        vm.warp(block.timestamp + 4 days);
        staker.claimReward(user2);
        uint256 expectedRewards = 10 * 7 * rewards - rewardDebt; // there are 10 tokens and 7 days have passed since the beginning
        assertEq(rewardToken.balanceOf(user2), expectedRewards);

        vm.stopPrank();

        vm.startPrank(user1);
        vm.warp(block.timestamp + 2 days);
        staker.claimReward(user1);
        expectedRewards = 9 * 2 * rewards; // 9 days since the beginning
        assertEq(rewardToken.balanceOf(user1), expectedRewards);
    }
}
