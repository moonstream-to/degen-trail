// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Degen Trail bandit contract
 * @author Moonstream Engineering (engineering@moonstream.to)
 *
 * A Bandit implements a fully on-chain single-player fog-of-war mechanic that produces RNG via two
 * player-submitted transactions. First, a player submits a transaction expressing their intent to
 * generate RNG. Second, the player submits a transaction that uses RNG derived from the block hash
 * of their first transaction.
 *
 * The player has a limited number of blocks to submit the second transaction. If they fail to submit
 * it in time, the entropy is wasted.
 *
 * The player may also elect to re-roll RNG by submitting a new transaction before the block deadline
 * in which they pay a fee to re-roll. If they elect to do this, the block hash of the block in which
 * the transaction representing their intent to re-roll is used as the new source of entropy. The block
 * deadline is then calculated from this transaction block.
 */
contract Bandit {
    // Number of blocks that players have to act once. Exceeding this deadline after their roll action
    // will result in the roll being wasted.
    uint256 public BlocksToAct;

    // Fee token (ERC20).
    address public FeeToken;

    // Fee for first roll.
    uint256 public RollFee;

    // Fee for re-roll.
    uint256 public RerollFee;

    // Block number of last roll for player.
    mapping(address => uint256) public LastRollForPlayer;

    // Block number for last roll for an NFT.
    mapping(address => mapping(uint256 => uint256)) public LastRollForNFT;

    // Current RNG for player.
    mapping(address => uint256) public RNGForPlayer;

    // Current RNG for an NFT.
    mapping(address => mapping(uint256 => uint256)) public RNGForNFT;

    constructor(uint256 blocksToAct, address feeToken, uint256 rollFee, uint256 rerollFee) {
        require(blocksToAct > 0, "blocksToAct must be positive");
        BlocksToAct = blocksToAct;
        FeeToken = feeToken;
        RollFee = rollFee;
        RerollFee = rerollFee;
    }

    function rollForPlayer() public {
    }
}
