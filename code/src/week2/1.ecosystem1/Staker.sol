// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./RewardToken.sol";
import "./NFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title Staker
 * @notice A contract for staking NFTs and earning rewards in a reward token.
 * @dev Implements ERC721 staking functionality with reward calculation based on a time accumulator.
 */
contract Staker is IERC721Receiver, Ownable2Step {
    error ClaimTooSoon(uint256 nextRewardTime, uint256 currentTime);
    error NothingToClaim();
    error NotNFTOwner(uint256 tokenId, address owner);
    error WrongNFTCaller(address nftAddress, address callerAddress);

    event AccumulatorUpdated(
        uint256 lastRewardTime,
        uint256 accumulatorRewardPerNFT
    );
    event Staked(
        address indexed beneficiary,
        uint256 amount,
        uint256 rewardDebt
    );
    event Rewards(address indexed beneficiary, uint256 rewards);
    event Withdrawn(address indexed withdrawer, uint256 tokenId);

    uint256 public immutable rewards;
    RewardToken public token;
    NFT public nft;

    struct UserInfo {
        uint256 amount; // number of staked NFTs
        uint256 rewardDebt;
    }

    uint256 public lastRewardTime;
    uint256 public accumulatorRewardPerNFT;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => address) public tokenOwners;

    constructor(RewardToken _token, NFT _nft) Ownable(msg.sender) {
        token = _token;
        nft = _nft;
        rewards = 10 ether;
        lastRewardTime = block.timestamp;
    }

    /**
     * @notice Updates reward accumulator and last reward time based on current time.
     * @dev Calculates the number of days since the last update and adjusts the reward accumulator accordingly.
     *      It's designed to be called before any staking, claiming, or withdrawing actions.
     * @return _lastRewardTime The updated last reward time.
     * @return _accumulatorRewardPerNFT The updated reward accumulator per NFT.
     */
    function update()
        public
        returns (uint256 _lastRewardTime, uint256 _accumulatorRewardPerNFT)
    {
        _lastRewardTime = lastRewardTime;
        _accumulatorRewardPerNFT = accumulatorRewardPerNFT;
        uint256 numberDays = (block.timestamp - _lastRewardTime) / 1 days;
        if (numberDays > 0) {
            _accumulatorRewardPerNFT =
                _accumulatorRewardPerNFT +
                numberDays *
                rewards;

            _lastRewardTime = _lastRewardTime + (numberDays * 1 days);
            lastRewardTime = _lastRewardTime;
            accumulatorRewardPerNFT = _accumulatorRewardPerNFT;
            emit AccumulatorUpdated(_lastRewardTime, _accumulatorRewardPerNFT);
        }
    }

    /**
     * @notice Stakes a specific NFT in the contract.
     * @dev Transfers the specified NFT (tokenId) from the sender to the contract and updates staking records.
     *      Requires that the sender is the owner of the NFT.
     * @param tokenId The unique identifier of the NFT to be staked.
     * @custom:error NotNFTOwner Thrown if the sender is not the owner of the NFT.
     */
    function stake(uint256 tokenId) external {
        if (nft.ownerOf(tokenId) != msg.sender)
            revert NotNFTOwner(tokenId, nft.ownerOf(tokenId));

        _stake(msg.sender, tokenId);

        nft.transferFrom(msg.sender, address(this), tokenId);
    }

    /**
     * @notice Claims accumulated rewards for the sender's staked NFTs.
     * @dev Calculates and mints reward tokens based on the amount of staked NFTs and accumulated rewards per NFT.
     *      Updates the reward debt to the current accumulated amount after claiming.
     *      Rewards can only be claimed if a day has passed since the last claim.
     * @param receiver The address to receive the claimed reward tokens.
     * @custom:error ClaimTooSoon Thrown if the claim is made before a day has passed since the last reward time.
     * @custom:error NothingToClaim Thrown if the sender has no staked NFTs to claim rewards for.
     */
    function claimReward(address receiver) external {
        if (lastRewardTime + 1 days > block.timestamp)
            revert ClaimTooSoon(lastRewardTime + 1 days, block.timestamp);
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount == 0) revert NothingToClaim();

        (, uint256 _accumulatorRewardPerNFT) = update();
        uint256 accumulatedRewards = user.amount * _accumulatorRewardPerNFT;
        uint256 userRewards = accumulatedRewards - user.rewardDebt;

        user.rewardDebt = accumulatedRewards; // start-over

        token.mint(receiver, userRewards);
        emit Rewards(receiver, userRewards);
    }

    /**
     * @notice Withdraws a staked NFT and updates the user's stake records.
     * @dev Transfers the specified NFT (tokenId) from the contract to the given receiver address.
     *      Updates the user's staked amount and reduces the reward debt accordingly.
     *      Requires that the sender is the current staker of the NFT.
     * @param tokenId The unique identifier of the NFT to be withdrawn.
     * @param receiver The address to receive the withdrawn NFT.
     * @custom:error NotNFTOwner Thrown if the sender is not the current staker of the NFT.
     */
    function withdraw(uint256 tokenId, address receiver) external {
        if (tokenOwners[tokenId] != msg.sender)
            revert NotNFTOwner(tokenId, tokenOwners[tokenId]);

        UserInfo storage user = userInfo[msg.sender];
        (, uint256 _accumulatorRewardPerNFT) = update();

        delete tokenOwners[tokenId];
        user.amount = user.amount - 1;
        user.rewardDebt = user.rewardDebt - _accumulatorRewardPerNFT; // 1 NFT removed

        nft.safeTransferFrom(address(this), receiver, tokenId);
        emit Withdrawn(receiver, tokenId);
    }

    /**
     * @notice Withdraws a staked NFT and claims accumulated rewards in a single transaction.
     * @dev Combines the functionality of withdrawing a staked NFT and claiming rewards.
     *      The specified NFT is transferred to the receiver, and reward tokens are minted to them.
     *      Ensures that a day has passed for reward eligibility and that the sender is the staker of the NFT.
     * @param tokenId The unique identifier of the NFT to be withdrawn.
     * @param receiver The address to receive the withdrawn NFT and reward tokens.
     * @custom:error NotNFTOwner Thrown if the sender is not the current staker of the NFT.
     * @custom:error ClaimTooSoon Thrown if a claim is attempted before a day has passed since the last reward time.
     * @custom:error NothingToClaim Thrown if there are no rewards to claim for the sender.
     */
    function withdrawAndClaim(uint256 tokenId, address receiver) external {
        if (tokenOwners[tokenId] != msg.sender)
            revert NotNFTOwner(tokenId, tokenOwners[tokenId]);
        if (lastRewardTime + 1 days > block.timestamp)
            revert ClaimTooSoon(lastRewardTime + 1 days, block.timestamp);

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount == 0) revert NothingToClaim();

        (, uint256 _accumulatorRewardPerNFT) = update();
        uint256 accumulatedRewards = user.amount * _accumulatorRewardPerNFT;
        uint256 userRewards = accumulatedRewards - user.rewardDebt;

        user.rewardDebt = accumulatedRewards; // start-over

        delete tokenOwners[tokenId];
        user.amount = user.amount - 1; // 1 NFT removed
        user.rewardDebt = user.rewardDebt - _accumulatorRewardPerNFT; // 1 NFT removed

        token.mint(receiver, userRewards);
        nft.safeTransferFrom(address(this), receiver, tokenId);
        emit Withdrawn(receiver, tokenId);
        emit Rewards(receiver, userRewards);
    }

    /**
     * @notice Handles the receipt of an NFT, automatically staking it in the contract.
     * @dev Implements ERC721's `onERC721Received` to allow direct staking of NFTs upon transfer.
     *      This function enables users to stake their NFTs by simply transferring them to the contract,
     *      without needing a separate approval step, saving gas and streamlining the process.
     * @param from The address sending the NFT to the contract.
     * @param tokenId The identifier of the NFT being transferred.
     * @return bytes4 Returns the function selector to confirm the contract's ability to handle ERC721 tokens.
     * @custom:error WrongNFTCaller Thrown if the NFT is sent from an unexpected contract address.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public override returns (bytes4) {
        if (msg.sender != address(nft))
            revert WrongNFTCaller(address(nft), msg.sender);

        _stake(from, tokenId);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Transfers ownership of the associated RewardToken contract.
     * @dev Allows the owner of the Staker contract to transfer ownership of the RewardToken contract.
     *      This function is only callable by the current owner of the Staker contract.
     * @param newOwner The address to which ownership of the RewardToken contract will be transferred.
     **/
    function transferOwnershipToken(address newOwner) external onlyOwner {
        token.transferOwnership(newOwner);
    }

    function acceptTokenOwnership() external onlyOwner {
        token.acceptOwnership();
    }

    /**
     * @notice Stakes an NFT in the contract on behalf of a user.
     * @dev Internal function to handle the logic of staking an NFT. Updates the user's staked amount
     *      and reward debt based on the current accumulator value.
     *      Emits a Staked event upon successful staking.
     * @param staker The address of the user who is staking the NFT.
     * @param tokenId The identifier of the NFT being staked.
     */
    function _stake(address staker, uint256 tokenId) private {
        (, uint256 _accumulatorRewardPerNFT) = update();
        UserInfo storage user = userInfo[staker];

        tokenOwners[tokenId] = staker;
        user.amount = user.amount + 1;
        user.rewardDebt = user.rewardDebt + _accumulatorRewardPerNFT; // 1 NFT added
        emit Staked(staker, user.amount, user.rewardDebt);
    }
}
