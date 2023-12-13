// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week1/4.untrusted-escrow/UntrustedEscrow.sol";
import "../../mocks/MockERC20.sol";

contract UntrustedEscrowTest is Test {
    error InsufficientBalance(uint256 available);
    error InvalidWithdrawalTime(uint256 currentTime, uint256 releaseTime);

    UntrustedEscrow escrow;
    MockERC20 token;
    address buyer;
    address seller;

    uint256 constant initialTokenSupply = 1e6; // 1 million tokens
    uint256 constant depositAmount = 1000; // 1000 tokens

    function setUp() public {
        // Set up buyer and seller addresses
        buyer = address(1);
        seller = address(2);

        token = new MockERC20("TestToken", "TT");
        escrow = new UntrustedEscrow();

        // Allocate tokens to the buyer
        token.mint(buyer, initialTokenSupply);

        // Approve the escrow contract to spend buyer's tokens
        vm.prank(buyer);
        token.approve(address(escrow), depositAmount);
    }

    function testCreateEscrow() public {
        // Create an escrow
        vm.prank(buyer);
        escrow.createEscrow(address(token), seller, depositAmount);

        // Check escrow details
        (uint256 amount, uint256 releaseTime) = escrow.getEscrowDetails(seller, address(token));
        assertEq(amount, depositAmount, "Incorrect escrow amount");
        assertEq(releaseTime, block.timestamp + 3 days, "Incorrect release time");
    }

    function testWithdrawEscrow() public {
        vm.prank(buyer);
        escrow.createEscrow(address(token), seller, depositAmount);

        // Fast forward time to surpass the escrow period
        vm.warp(block.timestamp + 4 days);

        // Withdraw from the escrow
        vm.prank(seller);
        escrow.withdrawEscrow(address(token));

        // Check seller's token balance
        assertEq(token.balanceOf(seller), depositAmount, "Withdrawal failed");
        (uint256 amount, uint256 releaseTime) = escrow.getEscrowDetails(seller, address(token));
        assertEq(amount, 0, "Incorrect escrow amount");
        assertEq(releaseTime, 0, "Incorrect release time");
    }

    function testInvalidWithdrawalTime() public {
        vm.prank(buyer);
        escrow.createEscrow(address(token), seller, depositAmount);

        // Attempt to withdraw before the release time
        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(InvalidWithdrawalTime.selector, block.timestamp, block.timestamp + 3 days)
        );
        escrow.withdrawEscrow(address(token));
    }

    function testCreateEscrowWithZeroAmount() public {
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, 0));
        escrow.createEscrow(address(token), seller, 0);
    }

    function testWithdrawFromEmptyEscrow() public {
        // Attempt to withdraw
        vm.prank(seller);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, 0));
        escrow.withdrawEscrow(address(token));
    }
}
