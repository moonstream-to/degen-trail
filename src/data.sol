// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @title Degen Trail stats
/// @author Moonstream Engineering (engineering@moonstream.to)
/// @notice This struct represents the stats of any NFT (wagons, items, etc.) that is used in The Degen Trail.
struct DegenTrailStats {
    uint256 speed;
    uint256 fight;
    uint256 repair;
    uint256 recovery;
}
