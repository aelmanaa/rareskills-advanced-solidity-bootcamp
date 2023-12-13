// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week1/2.godmode/TokenGodMode.sol";

contract TokenGodModeTest is Test {
    TokenGodMode token;
    address owner;
    address godAddress;
    address user1;
    address user2;

    error OnlyGod(address sender, address god);
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        owner = address(this);
        godAddress = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);

        token = new TokenGodMode("GodToken", "GT", godAddress);
    }

    function testDeploy() public {
        assertEq(token.name(), "GodToken");
        assertEq(token.symbol(), "GT");
        assertEq(token.godAddress(), godAddress);
    }

    function testSetGodAddressFailsForNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1));

        token.setGodAddress(user2);
        vm.stopPrank();
    }

    function testSetGodAddress() public {
        address newGodAddress = address(0x4);
        token.setGodAddress(newGodAddress);
        assertEq(token.godAddress(), newGodAddress);
    }

    function testGodTransfer() public {
        uint256 amount = 100;
        assertTrue(token.transfer(user1, amount));
        uint256 user1InitialBalance = token.balanceOf(user1);
        uint256 user2InitialBalance = token.balanceOf(user2);
        assertEq(user1InitialBalance, amount);

        vm.prank(godAddress);
        token.godTransfer(user1, user2, amount);

        uint256 user1FinalBalance = token.balanceOf(user1);
        uint256 user2FinalBalance = token.balanceOf(user2);
        assertEq(user1FinalBalance, user1InitialBalance - amount);
        assertEq(user2FinalBalance, user2InitialBalance + amount);
    }

    function testGodTransferFailsForNonGod() public {
        uint256 amount = 100;
        assertTrue(token.transfer(user1, amount));
        vm.expectRevert(abi.encodeWithSelector(OnlyGod.selector, owner, godAddress));
        token.godTransfer(user1, user2, amount);
    }
}
