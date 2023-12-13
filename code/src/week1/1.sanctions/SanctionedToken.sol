// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SanctionedToken
 * @notice This contract represents a token with sanction capabilities, inheriting from ERC20 and Ownable.
 * @dev Extends OpenZeppelin's ERC20 and Ownable to include sanctioning functionality. Allows the owner to ban and unban addresses.
 */
contract SanctionedToken is ERC20, Ownable2Step {
    error SenderAddressBanned(address sender);
    error RecipientAddressBanned(address recipient);
    error AccountNotBanned(address account);
    error AccountAlreadyBanned(address account);

    mapping(address => bool) private _banned;

    /**
     * @dev Modifier to prevent a banned address from participating in a transfer.
     * Throws `SenderAddressBanned` if `sender` is banned.
     * Throws `RecipientAddressBanned` if `recipient` is banned.
     * @param sender The address attempting to send tokens.
     * @param recipient The address attempting to receive tokens.
     */
    modifier notBanned(address sender, address recipient) {
        if (_banned[sender]) revert SenderAddressBanned(sender);
        if (_banned[recipient]) revert RecipientAddressBanned(recipient);
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(_msgSender()) {
        _mint(_msgSender(), 100 ether);
    }

    /**
     * @notice Bans an address from participating in token transfers.
     * @dev Adds the address to the banned list; reverts if the address is already banned.
     * @param account The address to be banned.
     */
    function banAddress(address account) public onlyOwner {
        if (_banned[account]) revert AccountAlreadyBanned(account);
        _banned[account] = true;
    }

    /**
     * @notice Unbans a previously banned address, allowing it to participate in token transfers again.
     * @dev Removes the address from the banned list; reverts if the address is not currently banned.
     * @param account The address to be unbanned.
     */
    function unbanAddress(address account) public onlyOwner {
        if (!_banned[account]) revert AccountNotBanned(account);
        _banned[account] = false;
    }

    /**
     * @notice Checks if an address is currently banned.
     * @dev Returns a boolean indicating the ban status of the address.
     * @param account The address to check for a ban.
     * @return A boolean indicating whether the address is banned.
     *
     */
    function isBanned(address account) public view returns (bool) {
        return _banned[account];
    }

    /**
     * @notice Transfers tokens to a specified address, subject to not being banned.
     * @dev Overrides ERC20's transfer function; includes the notBanned modifier to check sender and recipient.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating success of the transfer.
     *
     */
    function transfer(address to, uint256 value) public override notBanned(_msgSender(), to) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @notice Transfers tokens from one address to another, subject to not being banned.
     * @dev Overrides ERC20's transferFrom function; includes the notBanned modifier to check sender and recipient.
     * @param from The address from which tokens are transferred.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating success of the transfer.
     */
    function transferFrom(address from, address to, uint256 value) public override notBanned(from, to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}
