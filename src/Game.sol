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
    uint256 constant private u8mask = 2^8 - 1;

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
    constructor(uint256 blocksToAct, uint256 rollFee, uint256 rerollFee) Bandit(blocksToAct, address(this), rollFee, rerollFee) ERC20("Supply", "SUPPLY") {}

    /// @notice Describes the environment of a hex with the given j-coordinate.
    function environment(uint256 j) public pure returns (uint256) {
        return 3*(j >> 5) % 7;
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
}
