// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week2/1.ecosystem1/RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken token;
    address nonOwner = address(0x1234);

    function setUp() public {
        token = new RewardToken();
    }

    function testMintBurnByOwner() public {
        // Arrange
        address owner = address(this);
        uint256 amount = 1000;

        // Act and Assert
        token.mint(owner, amount);
        assertEq(token.balanceOf(owner), amount);

        token.burn(owner, amount);
        assertEq(token.balanceOf(owner), 0);
    }

    function testFailMintBurnByNonOwner() public {
        // Should fail
        vm.expectRevert();
        token.mint(nonOwner, 1000);
        vm.expectRevert();
        token.burn(nonOwner, 1000);
    }

    function testOwnershipTransferAndMintBurn() public {
        // Arrange
        address newOwner = nonOwner;
        uint256 amount = 1000;

        // Act
        token.transferOwnership(newOwner);

        // Assert that new owner can mint and burn
        vm.startPrank(newOwner); // `vm.prank` sets the next call to be from `newOwner`
        token.acceptOwnership();
        token.mint(newOwner, amount);
        token.burn(newOwner, amount);
    }
}
