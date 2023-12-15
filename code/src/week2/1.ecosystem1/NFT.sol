// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title NFT
 * @notice This contract manages NFT minting with discounts and royalties.
 * @dev Extends ERC721A, ERC2981, and Ownable2Step. Supports discounted minting for whitelisted addresses.
 */
contract NFT is ERC721A, ERC2981, Ownable2Step {
    error InsufficientBuyingAmount(uint256 price, uint256 amount);
    error EthTransferFailed(uint256 amount);
    error NoMoreSupply(uint256 amount);
    error AlreadyClaimed(address claimer, uint256 index);
    error InvalidProof();

    event FundsWithdrawn(address indexed receiver, uint256 amount);
    event Mint(address indexed receiver, uint256 nftAmount, uint256 totalPrice);

    bytes32 public immutable merkleRoot;
    uint256 public immutable discount; // bbps; Example: 10% discount is 1000
    uint256 public immutable initialPrice;
    uint256 public immutable supplyLimit;

    BitMaps.BitMap private _airdropList;

    constructor(
        bytes32 _merkleRoot,
        uint256 _discount,
        uint256 _initialPrice
    ) ERC721A("NFTSupp", "NFTS") Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        discount = _discount;
        initialPrice = _initialPrice;
        supplyLimit = 1000;
        super._setDefaultRoyalty(msg.sender, 250);
    }

    modifier checkSupply(uint256 amount) {
        if (totalSupply() + amount > supplyLimit) revert NoMoreSupply(amount);
        _;
    }

    /**
     * @notice Calculates the discounted price for minting a specified amount of NFTs.
     * @dev Calculates the price per NFT based on the initial price and a discount rate.
     *      The discount is applied uniformly across the specified amount of NFTs.
     * @param amount The number of NFTs for which to calculate the discounted price.
     * @return discountedPrice The total price for the specified amount of NFTs after applying the discount.
     */
    function getDiscountedPrice(
        uint256 amount
    ) public view returns (uint256 discountedPrice) {
        discountedPrice =
            amount *
            (initialPrice - ((initialPrice * discount) / _feeDenominator()));
    }

    /**
     * @notice Allows a user to mint NFTs at a discounted price if they are eligible.
     * @dev Mints `amount` of NFTs to `_receiver` at a discounted price if the `proof` is verified.
     *      Ensures the supply limit is not exceeded and handles the refund of excess Ether.
     * @param proof An array of bytes32 representing the Merkle proof to verify eligibility for the discount.
     * @param index The index in the airdrop list to check if the discount has already been claimed.
     * @param amount The number of NFTs to mint.
     * @param receiver The address that will receive the minted NFTs.
     * @custom:error InsufficientBuyingAmount Thrown if the Ether sent is less than the discounted price of the NFTs.
     * @custom:error AlreadyClaimed Thrown if the discount at the given index has already been claimed.
     * @custom:error InvalidProof Thrown if the provided Merkle proof is invalid.
     */
    function mintDiscount(
        bytes32[] calldata proof,
        uint256 index,
        uint256 amount,
        address receiver
    ) external payable checkSupply(amount) {
        uint256 discountedPrice = getDiscountedPrice(amount);
        if (discountedPrice > msg.value) {
            revert InsufficientBuyingAmount(discountedPrice, msg.value);
        }
        if (BitMaps.get(_airdropList, index))
            revert AlreadyClaimed(msg.sender, index);

        // verify proof
        _verifyProof(proof, index, amount, msg.sender);

        // set airdrop as claimed
        BitMaps.setTo(_airdropList, index, true);

        // mint tokens
        _safeMint(receiver, amount);
        if (msg.value > discountedPrice) {
            uint256 change = msg.value - discountedPrice;
            sendETh(_msgSender(), change);
        }
        emit Mint(receiver, amount, discountedPrice);
    }

    /**
     * @notice Allows minting of a single NFT at the set initial price.
     * @dev Mints one NFT to `_receiver` for a fixed price. Refunds excess Ether if more than the price is sent.
     * @param receiver The address that will receive the minted NFT.
     * @custom:error InsufficientBuyingAmount Thrown if the Ether sent is less than the initial price of the NFT.
     */
    function mint(address receiver) external payable checkSupply(1) {
        if (initialPrice > msg.value) {
            revert InsufficientBuyingAmount(initialPrice, msg.value);
        }

        _safeMint(receiver, 1);
        if (msg.value > initialPrice) {
            uint256 change = msg.value - initialPrice;
            sendETh(_msgSender(), change);
        }

        emit Mint(receiver, 1, initialPrice);
    }

    /**
     * @notice Withdraws all funds from the contract to the owner's address.
     * @dev Transfers the entire balance of Ether held by the contract to the owner's address.
     *      Can only be called by the contract owner.
     * @custom:error EthTransferFailed Thrown if the Ether transfer fails.
     */
    function withdrawFunds() external onlyOwner {
        sendETh(_msgSender(), address(this).balance);
        emit FundsWithdrawn(_msgSender(), address(this).balance);
    }

    /**
     * @notice Checks if the contract supports a specific interface.
     * @dev Overrides the `supportsInterface` function from ERC721A and ERC2981.
     *      Used for interface detection in line with EIP-165.
     * @param interfaceId The bytes4 identifier of the interface.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _verifyProof(
        bytes32[] memory proof,
        uint256 index,
        uint256 amount,
        address addr
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, index, amount)))
        );
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();
    }

    function sendETh(address receiver, uint256 amount) private {
        (bool success, ) = payable(receiver).call{value: amount}("");
        if (!success) revert EthTransferFailed(amount);
    }
}
