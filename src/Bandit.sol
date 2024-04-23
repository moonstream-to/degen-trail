// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bandit contract meant to be used by accounts
/// @author Moonstream Engineering (engineering@moonstream.to)
///
/// @notice A Bandit implements a fully on-chain single-player fog-of-war mechanic that produces RNG via two
/// player-submitted transactions. First, a player submits a transaction expressing their intent to
/// generate RNG. Second, the player submits a transaction that uses RNG derived from the block hash
/// of their first transaction.
///
/// @notice The player has a limited number of blocks to submit the second transaction. If they fail to submit
/// it in time, the entropy is wasted.
///
/// @notice The player may also elect to re-roll RNG by submitting a new transaction before the block deadline
/// in which they pay a fee to re-roll. If they elect to do this, the block hash of the block in which
/// the transaction representing their intent to re-roll is used as the new source of entropy. The block
/// deadline is then calculated from this transaction block.
contract PlayerBandit {
    using SafeERC20 for IERC20;

    event PlayerRoll(address indexed player);
    event PlayerEntropyUsed(address indexed player, uint256 entropy);

    // Number of blocks that players have to act once. Exceeding this deadline after their roll action
    // will result in the roll being wasted.
    uint256 public BlocksToAct;

    // Fee token (ERC20).
    IERC20 public FeeToken;

    // Fee for first roll.
    uint256 public RollFee;

    // Fee for re-roll.
    uint256 public RerollFee;

    // Block number of last roll for player.
    mapping(address => uint256) public LastRollForPlayer;

    error PlayerDeadlineExceeded(address player);
    error WaitForPlayerTick(address player);

    function _postRoll() internal virtual {}

    /// @param blocksToAct Number of blocks that a player has to decide whether to accept their fate or re-roll. This parameter applies to every such decision point.
    /// @param feeTokenAddress Address of ERC20 token which represents fees.
    /// @param rollFee Fee for first roll on any action.
    /// @param rerollFee Fee for re-roll on any action, assuming player doesn't want to accept their fate.
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee) {
        BlocksToAct = blocksToAct;
        FeeToken = IERC20(feeTokenAddress);
        RollFee = rollFee;
        RerollFee = rerollFee;
    }

    function rollForPlayer() public returns (uint256) {
        FeeToken.safeTransferFrom(msg.sender, address(this), RollFee);
        LastRollForPlayer[msg.sender] = block.number;
        emit PlayerRoll(msg.sender);
        _postRoll();
        return block.number;
    }

    function _checkPlayerDeadline(address player) internal view {
        uint256 elapsed = block.number - LastRollForPlayer[player];
        if (elapsed > BlocksToAct) {
            revert PlayerDeadlineExceeded(player);
        }
    }

    function _waitForTickForPlayer(address player) internal view {
        if (block.number <= LastRollForPlayer[player]) {
            revert WaitForPlayerTick(player);
        }
    }

    function _entropyForPlayer(address player) internal returns (uint256) {
        _checkPlayerDeadline(player);
        _waitForTickForPlayer(player);
        uint256 entropy = uint256(blockhash(LastRollForPlayer[player]));
        emit PlayerEntropyUsed(player, entropy);
        delete LastRollForPlayer[player];
        return entropy;
    }

    function rerollForPlayer() public returns (uint256) {
        _checkPlayerDeadline(msg.sender);
        FeeToken.safeTransferFrom(msg.sender, address(this), RerollFee);
        LastRollForPlayer[msg.sender] = block.number;
        emit PlayerRoll(msg.sender);
        _postRoll();
        return block.number;
    }
}

/// @title Bandit contract meant to be used by ERC721 tokens
/// @author Moonstream Engineering (engineering@moonstream.to)
///
/// @notice This is analogous to the PlayerBandit, except that each action is related to an ERC721 token
/// rather than an Ethereum account.
contract NFTBandit {
    using SafeERC20 for IERC20;

    event NFTRoll(address indexed tokenAddress, uint256 indexed tokenID);
    event NFTEntropyUsed(address indexed tokenAddress, uint256 indexed tokenID, uint256 entropy);

    // Number of blocks that players have to act once. Exceeding this deadline after their roll action
    // will result in the roll being wasted.
    uint256 public BlocksToAct;

    // Fee token (ERC20).
    IERC20 public FeeToken;

    // Fee for first roll.
    uint256 public RollFee;

    // Fee for re-roll.
    uint256 public RerollFee;

    // Block number for last roll for an NFT.
    mapping(address => mapping(uint256 => uint256)) public LastRollForNFT;

    error NFTDeadlineExceeded(address tokenAddress, uint256 tokenID);
    error WaitForNFTTick(address tokenAddress, uint256 tokenID);
    error NFTNotOwnedByPlayer(address player, address tokenAddress, uint256 tokenID);

    function _preRollForNFT(address tokenAddress, uint256 tokenID) internal virtual {}
    function _postRoll() internal virtual {}

    /// @param blocksToAct Number of blocks that a player has to decide whether to accept their fate or re-roll. This parameter applies to every such decision point.
    /// @param feeTokenAddress Address of ERC20 token which represents fees.
    /// @param rollFee Fee for first roll on any action.
    /// @param rerollFee Fee for re-roll on any action, assuming player doesn't want to accept their fate.
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee) {
        BlocksToAct = blocksToAct;
        FeeToken = IERC20(feeTokenAddress);
        RollFee = rollFee;
        RerollFee = rerollFee;
    }

    function _checkNFTOwnership(address player, address tokenAddress, uint256 tokenID) internal view {
        IERC721 nft = IERC721(tokenAddress);
        if (nft.ownerOf(tokenID) != player) {
            revert NFTNotOwnedByPlayer(player, tokenAddress, tokenID);
        }
    }

    function rollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256) {
        _checkNFTOwnership(msg.sender, tokenAddress, tokenID);
        _preRollForNFT(tokenAddress, tokenID);
        FeeToken.safeTransferFrom(msg.sender, address(this), RollFee);
        LastRollForNFT[tokenAddress][tokenID] = block.number;
        emit NFTRoll(tokenAddress, tokenID);
        _postRoll();
        return block.number;
    }

    function _checkNFTDeadline(address tokenAddress, uint256 tokenID) internal view {
        uint256 elapsed = block.number - LastRollForNFT[tokenAddress][tokenID];
        if (elapsed > BlocksToAct) {
            revert NFTDeadlineExceeded(tokenAddress, tokenID);
        }
    }

    function _waitForTickForNFT(address tokenAddress, uint256 tokenID) internal view {
        if (block.number <= LastRollForNFT[tokenAddress][tokenID]) {
            revert WaitForNFTTick(tokenAddress, tokenID);
        }
    }

    function _entropyForNFT(address tokenAddress, uint256 tokenID) internal returns (uint256) {
        _checkNFTDeadline(tokenAddress, tokenID);
        _waitForTickForNFT(tokenAddress, tokenID);
        uint256 entropy = uint256(blockhash(LastRollForNFT[tokenAddress][tokenID]));
        emit NFTEntropyUsed(tokenAddress, tokenID, entropy);
        delete LastRollForNFT[tokenAddress][tokenID];
        return entropy;
    }

    function rerollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256) {
        _checkNFTOwnership(msg.sender, tokenAddress, tokenID);
        _checkNFTDeadline(tokenAddress, tokenID);
        FeeToken.safeTransferFrom(msg.sender, address(this), RerollFee);
        LastRollForNFT[tokenAddress][tokenID] = block.number;
        emit NFTRoll(tokenAddress, tokenID);
        _postRoll();
        return block.number;
    }
}
