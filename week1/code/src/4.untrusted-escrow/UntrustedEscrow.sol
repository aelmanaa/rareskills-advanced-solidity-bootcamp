// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title UntrustedEscrow
 * @notice This contract acts as an escrow for ERC20 tokens, where a buyer can deposit tokens that a seller can withdraw after a 3-day period.
 * @dev The contract handles multiple escrows per seller, each for different ERC20 tokens, using SafeERC20 for secure token transfers and ReentrancyGuard for preventing reentrancy attacks.
 */
contract UntrustedEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InsufficientBalance(uint256 available);
    error InvalidWithdrawalTime(uint256 currentTime, uint256 releaseTime);

    struct Escrow {
        uint256 amount;
        uint256 releaseTime;
    }

    // Mapping from seller to token address to escrow
    mapping(address => mapping(address => Escrow)) public escrows;

    event EscrowCreated(
        address indexed tokenAddress,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint256 releaseTime
    );
    event EscrowWithdrawn(
        address indexed tokenAddress,
        address indexed seller,
        uint256 amount
    );

    /**
     * @notice Creates an escrow for the specified ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     * @param seller The address of the seller who can withdraw the tokens.
     * @param amount The amount of tokens to put into escrow.
     */
    function createEscrow(
        address tokenAddress,
        address seller,
        uint256 amount
    ) external {
        if (amount == 0) revert InsufficientBalance(0);

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        Escrow storage escrow = escrows[seller][tokenAddress];
        escrow.amount += amount;
        escrow.releaseTime = block.timestamp + 3 days;

        emit EscrowCreated(
            tokenAddress,
            msg.sender,
            seller,
            amount,
            escrow.releaseTime
        );
    }

    /**
     * @notice Withdraws tokens from the escrow after the release time.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     */
    function withdrawEscrow(address tokenAddress) external nonReentrant {
        Escrow memory escrow = escrows[msg.sender][tokenAddress];

        if (escrow.amount == 0) revert InsufficientBalance(0);
        if (escrow.releaseTime > block.timestamp) {
            revert InvalidWithdrawalTime(block.timestamp, escrow.releaseTime);
        }

        delete escrows[msg.sender][tokenAddress];

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, escrow.amount);

        emit EscrowWithdrawn(tokenAddress, msg.sender, escrow.amount);
    }

    /**
     * @notice Retrieves the details of an escrow.
     * @param seller The address of the seller.
     * @param tokenAddress The address of the ERC20 token.
     * @return amount The amount of tokens in escrow.
     * @return releaseTime The time when the tokens can be withdrawn.
     */
    function getEscrowDetails(
        address seller,
        address tokenAddress
    ) public view returns (uint256 amount, uint256 releaseTime) {
        Escrow memory escrow = escrows[seller][tokenAddress];
        return (escrow.amount, escrow.releaseTime);
    }
}
