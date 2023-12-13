// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../../src/week1/3.tokensale/TokenSale.sol";

contract TokenSaleTest is Test {
    TokenSale tokenSale;
    address user;
    uint256 constant initialEthUserBalance = 10000 ether;

    error InsufficientBuyingAmount(uint256 price, uint256 amount);
    error InsufficientBalance(uint256 balance, uint256 amount);
    error EthTransferFailed(uint256 amount);
    error SlippageToleranceExceeded(uint256 userLimit, uint256 actual);

    receive() external payable {}

    function setUp() public {
        user = address(this);
        tokenSale = new TokenSale("CurveToken", "CT");
        vm.deal(user, initialEthUserBalance);
    }

    function testInitialSetup() public {
        assertEq(tokenSale.name(), "CurveToken");
        assertEq(tokenSale.symbol(), "CT");
        assertEq(address(tokenSale).balance, 0);
        assertEq(tokenSale.totalSupply(), 0);
    }

    function testBuyTokens() public {
        uint256 tokenAmount = 10;
        uint256 price = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 maxEth = price + 1 ether; // slippage tolerance

        tokenSale.buyTokens{value: price}(tokenAmount, maxEth);

        assertEq(tokenSale.balanceOf(user), tokenAmount);
        assertEq(address(tokenSale).balance, price);
        assertEq(tokenSale.totalSupply(), tokenAmount);
        assertEq(user.balance, initialEthUserBalance - price);
    }

    function testBuyTokensWithExcessEther() public {
        uint256 tokenAmount = 10;
        uint256 price = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 excessAmount = 1 ether;
        uint256 maxEth = price + 1 ether; // slippage tolerance

        tokenSale.buyTokens{value: price + excessAmount}(tokenAmount, maxEth);
        assertEq(tokenSale.balanceOf(user), tokenAmount);
        assertEq(address(tokenSale).balance, price);
        assertEq(tokenSale.totalSupply(), tokenAmount);
        assertEq(user.balance, initialEthUserBalance - price);
    }

    function testBuyTokensInsufficientEther() public {
        uint256 tokenAmount = 10;
        uint256 price = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 wrongPrice = price - 1;
        uint256 maxEth = price + 1 ether; // slippage tolerance

        vm.expectRevert(abi.encodeWithSelector(InsufficientBuyingAmount.selector, price, wrongPrice));
        tokenSale.buyTokens{value: wrongPrice}(tokenAmount, maxEth);
    }

    function testBuyTokensSlippageToleranceExceeded() public {
        uint256 tokenAmount = 10;
        uint256 price = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 maxEth = price - 1; // Intentionally set lower than the price

        vm.expectRevert(abi.encodeWithSelector(SlippageToleranceExceeded.selector, maxEth, price));
        tokenSale.buyTokens{value: price}(tokenAmount, maxEth);
    }

    function testSellTokens() public {
        uint256 tokenAmount = 10;
        uint256 buyPrice = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 maxEth = buyPrice + 1 ether; // slippage tolerance
        tokenSale.buyTokens{value: buyPrice}(tokenAmount, maxEth);

        uint256 sellAmount = tokenSale.calculateSellPrice(tokenAmount);
        uint256 minEth = sellAmount - 1; // slippage tolerance
        tokenSale.sellTokens(tokenAmount, minEth);

        assertEq(tokenSale.balanceOf(user), 0);
        assertEq(user.balance, initialEthUserBalance - buyPrice + sellAmount);
    }

    function testSellTokensInsufficientBalance() public {
        uint256 tokenAmount = 10;
        uint256 smallAmount = 1;
        uint256 maxEth = 1 ether; // slippage tolerance
        tokenSale.buyTokens{value: 10 ether}(smallAmount, maxEth);

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, smallAmount, tokenAmount));
        tokenSale.sellTokens(tokenAmount, 1 ether);
    }

    function testSellTokensSlippageToleranceExceeded() public {
        uint256 tokenAmount = 10;
        uint256 buyPrice = tokenSale.calculateBuyPrice(tokenAmount);
        tokenSale.buyTokens{value: buyPrice}(tokenAmount, buyPrice);

        uint256 sellAmount = tokenSale.calculateSellPrice(tokenAmount);
        uint256 minEth = sellAmount + 1; // Intentionally set higher than the return amount

        vm.expectRevert(abi.encodeWithSelector(SlippageToleranceExceeded.selector, minEth, sellAmount));
        tokenSale.sellTokens(tokenAmount, minEth);
    }

    function testBuyPriceCalculations() public {
        uint256[] memory tokenAmounts = new uint256[](5);
        uint256[] memory expectedPrices = new uint256[](5);

        // P = tokenAmount * slope * (tokenAmount + 2 * totalSupply) / 2
        // slope = 1
        // precompute offchain , after each buy, the supply changes

        tokenAmounts[0] = 10;
        expectedPrices[0] = 50;
        tokenAmounts[1] = 500;
        expectedPrices[1] = 130000;
        tokenAmounts[2] = 1000;
        expectedPrices[2] = 1010000;
        tokenAmounts[3] = 5000;
        expectedPrices[3] = 20050000;
        tokenAmounts[4] = 10000;
        expectedPrices[4] = 115100000;

        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            uint256 calculatedPrice = tokenSale.calculateBuyPrice(tokenAmounts[i]);
            uint256 maxEth = calculatedPrice + 1 ether; // slippage tolerance
            assertEq(calculatedPrice, expectedPrices[i], "Buy price mismatch at index: ");

            tokenSale.buyTokens{value: calculatedPrice}(tokenAmounts[i], maxEth);
        }
    }

    function testSellPriceCalculations() public {
        // buy
        uint256 tokenAmount = 1000000;
        uint256 price = tokenSale.calculateBuyPrice(tokenAmount);
        uint256 maxEth = price + 1 ether; // slippage tolerance
        tokenSale.buyTokens{value: price}(tokenAmount, maxEth);

        uint256[] memory tokenAmounts = new uint256[](5);
        uint256[] memory expectedPrices = new uint256[](5);

        tokenAmounts[0] = 10;
        expectedPrices[0] = 9999950;
        tokenAmounts[1] = 500;
        expectedPrices[1] = 499870000;
        tokenAmounts[2] = 1000;
        expectedPrices[2] = 998990000;
        tokenAmounts[3] = 5000;
        expectedPrices[3] = 4979950000;
        tokenAmounts[4] = 10000;
        expectedPrices[4] = 9884900000;

        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            uint256 calculatedPrice = tokenSale.calculateSellPrice(tokenAmounts[i]);
            uint256 minEth = calculatedPrice - 1; // slippage tolerance
            assertEq(calculatedPrice, expectedPrices[i], "Sell price mismatch at index: ");

            tokenSale.sellTokens(tokenAmounts[i], minEth);
        }
    }
}
