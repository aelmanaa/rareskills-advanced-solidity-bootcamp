// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenSale
 * @notice This contract represents an ERC20 token with a linear bonding curve for token sale and buyback.
 * @dev Extends OpenZeppelin's ERC20. Includes functionality for buying and selling tokens based on a linear bonding curve.
 */
contract TokenSale is ERC20 {
    error InsufficientBuyingAmount(uint256 price, uint256 amount);
    error InsufficientBalance(uint256 balance, uint256 amount);
    error EthTransferFailed(uint256 amount);
    error SlippageToleranceExceeded(uint256 userLimit, uint256 actual);

    uint256 private constant slope = 1;

    event TokensBought(address indexed buyer, uint256 amount, uint256 price);
    event TokensSold(address indexed seller, uint256 amount, uint256 price);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice Calculates the price for buying tokens.
     * @dev Implements the linear bonding curve formula: P = tokenAmount * slope * (tokenAmount + 2 * totalSupply) / 2
     * @param tokenAmount The number of tokens to buy.
     * @return price The price in ETH for buying tokenAmount tokens.
     */
    function calculateBuyPrice(
        uint256 tokenAmount
    ) public view returns (uint256 price) {
        return
            (tokenAmount * slope * (tokenAmount + (totalSupply() << 1))) >> 1;
    }

    /**
     * @notice Allows users to buy tokens based on the bonding curve.
     * @param tokenAmount The number of tokens to buy.
     * @param maxEth The maximum amount of ETH the user is willing to pay.
     */
    function buyTokens(uint256 tokenAmount, uint256 maxEth) external payable {
        uint256 price = calculateBuyPrice(tokenAmount);
        if (price > msg.value) {
            revert InsufficientBuyingAmount(price, msg.value);
        }
        if (price > maxEth) revert SlippageToleranceExceeded(maxEth, price);
        _mint(_msgSender(), tokenAmount);
        if (msg.value > price) {
            uint256 change = msg.value - price;
            (bool success, ) = _msgSender().call{value: change}("");
            if (!success) revert EthTransferFailed(change);
        }
        emit TokensBought(_msgSender(), tokenAmount, price);
    }

    /**
     * @notice Calculates the amount received from selling tokens.
     * @dev Implements the linear bonding curve formula: S = tokenAmount * slope * (2 * totalSupply - tokenAmount) / 2
     * @param tokenAmount The number of tokens to sell.
     * @return amount The amount received for selling tokenAmount tokens.
     */
    function calculateSellPrice(
        uint256 tokenAmount
    ) public view returns (uint256 amount) {
        return
            (tokenAmount * slope * ((totalSupply() << 1) - tokenAmount)) >> 1;
    }

    /**
     * @notice Allows users to sell tokens back to the contract.
     * @param tokenAmount The number of tokens to sell.
     * @param minEth The minimum amount of ETH the user expects to receive.
     */
    function sellTokens(uint256 tokenAmount, uint256 minEth) external {
        if (tokenAmount > balanceOf(_msgSender())) {
            revert InsufficientBalance(balanceOf(_msgSender()), tokenAmount);
        }
        uint256 amount = calculateSellPrice(tokenAmount);
        if (minEth > amount) revert SlippageToleranceExceeded(minEth, amount);
        _burn(_msgSender(), tokenAmount);
        (bool success, ) = _msgSender().call{value: amount}("");
        if (!success) revert EthTransferFailed(amount);
        emit TokensSold(_msgSender(), tokenAmount, amount);
    }
}
