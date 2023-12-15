// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title RewardToken
 * @notice A simple ERC20 token used for rewards in staking contracts or other applications.
 * @dev Extends OpenZeppelin's ERC20 and Ownable2Step. Provides functions for minting and burning tokens.
 */
contract RewardToken is ERC20, Ownable2Step {
    constructor() ERC20("Rewards Token", "TKR") Ownable(msg.sender) {}

    /**
     * @notice Mints `amount` of tokens to address `to`.
     * @dev Can only be called by the contract owner.
     * @param to Address to which the tokens will be minted.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns `amount` of tokens from address `from`.
     * @dev Can only be called by the contract owner.
     * @param from Address from which the tokens will be burned.
     * @param amount The number of tokens to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
