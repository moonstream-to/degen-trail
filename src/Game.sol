// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Bandit} from "./Bandit.sol";

/// @title Degen Trail game contract
/// @author Moonstream Engineering (engineering@moonstream.to)
///
/// @notice This is the game contract for The Degen Trail, a fully on-chain degenerate homage to The Oregon
/// Trail.
contract DegenTrail is Bandit, ERC20 {
    uint256 private constant u8mask = 0xFF;
    uint256 private constant u7mask = 0x7F;

    /// @notice Maps (i,j)-indices (vertical then horizontal) to the state of the corresponding hex on the game board.
    mapping(uint256 => mapping(uint256 => uint256)) public Hex;

    /// @notice For each environment, lists the cumulative distribution function for terrains in that environment.
    /// @dev Environments are: 0 - forest, 1 - prairie, 2 - river, 3 - arctic, 4 - marsh, 5 - badlands, 6 - hills
    /// @dev Terrain types are: 0 - plain, 1 - forest, 2 - swamp, 3 - water, 4 - mountain, 5 - desert, 6 - ice
    uint8[7][7] public EnvironmentDistributions = [
        [0, 90, 98, 123, 128, 128, 128],
        [90, 95, 100, 120, 120, 128, 128],
        [0, 0, 8, 128, 128, 128, 128],
        [0, 8, 8, 8, 28, 28, 128],
        [5, 10, 108, 128, 128, 128, 128],
        [18, 18, 18, 18, 28, 128, 128],
        [0, 43, 43, 48, 128, 128, 128]
    ];

    /// @param blocksToAct Number of blocks that a player has to decide whether to accept their fate or re-roll. This parameter applies to every such decision point.
    /// @param rollFee Fee for first roll on any action.
    /// @param rerollFee Fee for re-roll on any action, assuming player doesn't want to accept their fate.
    constructor(uint256 blocksToAct, uint256 rollFee, uint256 rerollFee)
        Bandit(blocksToAct, address(this), rollFee, rerollFee)
        ERC20("Supply", "SUPPLY")
    {
        uint256 prevBlockNumber = 0;
        if (block.number > 0) {
            prevBlockNumber = block.number - 1;
        }
        // Zero out the leading 12 bits of the block hash, to prevent overflows when adding 31 * j.
        uint256 startingEntropy = uint256(blockhash(prevBlockNumber)) >> 12 << 12;
        for (uint256 j = 0; j < 100; j++) {
            _explore(0, 2 * j, startingEntropy + (31 * j));
        }
    }

    /// @notice Internal method that explores a hex and sets its state.
    function _explore(uint256 i, uint256 j, uint256 entropy) internal {
        uint256 env = environment(i);
        uint8 maskedEntropy = uint8(entropy & u7mask);
        if (maskedEntropy < EnvironmentDistributions[env][6]) {
            // 1111
            Hex[i][j] = 13;
        } else if (maskedEntropy < EnvironmentDistributions[env][5]) {
            // 1011
            Hex[i][j] = 11;
        } else if (maskedEntropy < EnvironmentDistributions[env][4]) {
            // 1001
            Hex[i][j] = 9;
        } else if (maskedEntropy < EnvironmentDistributions[env][3]) {
            // 0111
            Hex[i][j] = 7;
        } else if (maskedEntropy < EnvironmentDistributions[env][2]) {
            // 0101
            Hex[i][j] = 5;
        } else if (maskedEntropy < EnvironmentDistributions[env][1]) {
            // 0011
            Hex[i][j] = 3;
        } else {
            // 0001
            Hex[i][j] = 1;
        }
    }

    /// @notice Describes the environment of a hex with the given j-coordinate.
    function environment(uint256 i) public pure returns (uint256) {
        return 3 * (i >> 5) % 7;
    }

    /// @notice Returns true if (i,j) is a valid coordinate for a hex on the game board.
    /// @dev (i,j) is only a valid coordinate for a hex on the game board if i and j have the same parity and if j < 200.
    /// @dev Predicate
    function hexp(uint256 i, uint256 j) public pure returns (bool) {
        if (j >= 200) {
            return false;
        }
        return (i & 1) ^ (j & 1) == 0;
    }

    /// @notice Returns true if (i1,j1) and (i2,j2) are neighbors on the game board.
    /// @dev Predicate
    function neighborsp(uint256 i1, uint256 j1, uint256 i2, uint256 j2) public pure returns (bool) {
        if (!hexp(i1, j1) || !hexp(i2, j2)) {
            return false;
        }
        if (i1 == i2) {
            if (j1 > j2) {
                return j1 - j2 == 2;
            } else {
                return j2 - j1 == 2;
            }
        } else if (i1 > i2) {
            if (i1 - i2 == 1) {
                if (j1 > j2) {
                    return j1 - j2 == 1;
                } else {
                    return j2 - j1 == 1;
                }
            }
        } else {
            if (i2 - i1 == 1) {
                if (j1 > j2) {
                    return j1 - j2 == 1;
                } else {
                    return j2 - j1 == 1;
                }
            }
        }

        return false;
    }

    /// @notice Returns the current state of the board for the hexes with the given indices.
    /// @dev This method is provided for convenience. Another alternative to calling this method would be to
    /// view the Hex mapping via a multicall contract.
    function board(uint256[2][] memory indices) external view returns (uint256[3][] memory) {
        uint256[3][] memory result = new uint256[3][](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            result[i][0] = indices[i][0];
            result[i][1] = indices[i][1];
            result[i][2] = Hex[indices[i][0]][indices[i][1]];
        }
        return result;
    }
}
