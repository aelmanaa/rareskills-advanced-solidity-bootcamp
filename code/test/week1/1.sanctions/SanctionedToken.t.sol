// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week1/1.sanctions/SanctionedToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SanctionedTokenTest is Test {
    SanctionedToken token;
    address owner;
    address user1;
    address user2;

    error OwnableUnauthorizedAccount(address account);
    error SenderAddressBanned(address sender);
    error RecipientAddressBanned(address recipient);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new SanctionedToken("MyToken", "MTK");
    }

    function testDeploy() public {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
    }

    function testBanAddressFailsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1));
        token.banAddress(user2);
    }

    function testUnbanAddressFailsForNonOwner() public {
        token.banAddress(user1);

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user2));
        token.unbanAddress(user1);
    }

    function testTransferBanSenderAddress() public {
        token.banAddress(owner);

        assertTrue(token.isBanned(owner));
        vm.expectRevert(abi.encodeWithSelector(SenderAddressBanned.selector, owner));
        token.transfer(user1, 100);
    }

    function testTransferBanRecipientAddress() public {
        token.banAddress(user1);

        assertTrue(token.isBanned(user1));
        vm.expectRevert(abi.encodeWithSelector(RecipientAddressBanned.selector, user1));
        token.transfer(user1, 100);
    }

    function testTransferUnbanAddress() public {
        uint256 amount = 100;
        uint256 senderInitialBalance = token.balanceOf(owner);
        uint256 recipientInitialBalance = token.balanceOf(user1);

        token.banAddress(user1);
        assertTrue(token.isBanned(user1));
        token.unbanAddress(user1);
        assertFalse(token.isBanned(user1));
        assertTrue(token.transfer(user1, amount));

        uint256 senderFinalBalance = token.balanceOf(address(this));
        uint256 recipientFinalBalance = token.balanceOf(user1);

        assertEq(senderFinalBalance, senderInitialBalance - amount, "Sender balance should decrease by 100");
        assertEq(recipientFinalBalance, recipientInitialBalance + amount, "Recipient balance should increase by 100");
    }

    function testTransferFromBanSenderAddress() public {
        uint256 amount = 100;
        token.transfer(user1, 500);
        vm.prank(user1);
        token.approve(address(this), amount);

        token.banAddress(user1);
        vm.expectRevert(abi.encodeWithSelector(SenderAddressBanned.selector, user1));
        token.transferFrom(user1, user2, amount);
    }

    function testTransferFromBanRecipientAddress() public {
        uint256 amount = 100;
        token.transfer(user1, 500);
        vm.prank(user1);
        token.approve(address(this), amount);

        token.banAddress(user2);
        vm.expectRevert(abi.encodeWithSelector(RecipientAddressBanned.selector, user2));
        token.transferFrom(user1, user2, amount);
    }

    function testTransferFromUnbanAddress() public {
        uint256 amount = 100;
        token.transfer(user1, 500);
        uint256 senderInitialBalance = token.balanceOf(user1);
        uint256 recipientInitialBalance = token.balanceOf(user2);

        vm.prank(user1);
        token.approve(address(this), amount);
        token.transferFrom(user1, user2, amount);

        uint256 senderFinalBalance = token.balanceOf(user1);
        uint256 recipientFinalBalance = token.balanceOf(user2);

        assertEq(senderFinalBalance, senderInitialBalance - amount, "Sender balance should decrease by 100");
        assertEq(recipientFinalBalance, recipientInitialBalance + amount, "Recipient balance should increase by 100");
    }
}
