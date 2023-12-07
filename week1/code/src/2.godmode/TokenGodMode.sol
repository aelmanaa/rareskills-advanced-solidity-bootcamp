// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title TokenGodMode
 * @notice This contract represents an ERC20 token with a "god mode" feature, allowing a special address to transfer tokens between any two addresses.
 * @dev Extends OpenZeppelin's ERC20 and Ownable. Includes functionality for a god mode address, set by the owner, to transfer tokens without restrictions.
 */
contract TokenGodMode is ERC20, Ownable2Step {
    error OnlyGod(address sender, address god);

    address private _godAddress;

    event GodAddressChanged(address indexed newGodAddress);

    constructor(string memory name, string memory symbol, address initialGodAddress)
        ERC20(name, symbol)
        Ownable(_msgSender())
    {
        _mint(_msgSender(), 100 ether);
        _setGodAddress(initialGodAddress);
    }

    /**
     * @notice Sets a new "god" address with special transfer privileges.
     * @dev Can only be called by the contract owner. Emits a `GodAddressChanged` event.
     * @param newGodAddress The address to be set as the new "god" address.
     */
    function setGodAddress(address newGodAddress) public onlyOwner {
        _setGodAddress(newGodAddress);
    }

    function _setGodAddress(address newGodAddress) internal {
        if (_godAddress != newGodAddress) {
            _godAddress = newGodAddress;
            emit GodAddressChanged(newGodAddress);
        }
    }

    /**
     * @notice Checks the current "god" address.
     * @dev Returns the address currently set as the "god" address.
     * @return The current "god" address.
     */
    function godAddress() public view returns (address) {
        return _godAddress;
    }

    /**
     * @notice Allows the "god" address to transfer tokens between any two addresses.
     * @dev Can only be called by the current "god" address.
     * @param from The address from which tokens are to be transferred.
     * @param to The address to receive the tokens.
     * @param amount The amount of tokens to be transferred.
     */
    function godTransfer(address from, address to, uint256 amount) public {
        if (_godAddress != _msgSender()) revert OnlyGod(_msgSender(), _godAddress);
        _transfer(from, to, amount);
    }
}
