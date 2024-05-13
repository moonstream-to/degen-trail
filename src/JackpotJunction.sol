// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC1155} from "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

/// @title Jackpot Junction game contract
/// @author Moonstream Engineering (engineering@moonstream.to)
///
/// @notice This is the game contract for The Degen Trail: Jackpot Junction, a game in world of The Degen Trail.
contract JackpotJunction is ERC1155 {
    // Probability masses are scaled by 2^20 = 1048576.
    uint256[5] public UnmodifiedOutcomes = [524288, 408934, 104857, 10487, 10];
    uint256[5] public ImprovedOutcomes = [469283, 408934, 154857, 15487, 15];

    // How many seconds a player has to act (reroll/accept).
    uint256 public SecondsToAct;

    // Costs (finest denomination of native token on the chain) to roll and reroll.
    uint256 public CostToRoll;
    uint256 public CostToReroll;

    // Item types: 0 (wagon cover), 1 (wagon body), 2 (wagon wheel), 3 (beast)
    // Terrain types: 0 (plain), 1 (forest), 2 (swamp), 3 (water), 4 (mountain), 5 (desert), 6 (ice)
    // Encoding of ERC1155 pool IDs: tier*28 + terrainType*4 + itemType
    mapping(uint256 => mapping(uint256 => uint256)) public CurrentTier;

    event TierUnlocked(uint256 indexed itemType, uint256 indexed terrainType, uint256 indexed tier, uint256 poolID);

    constructor(uint256 secondsToAct, uint256 costToRoll, uint256 costToReroll) ERC1155("https://github.com/moonstream-to/degen-trail") {
        SecondsToAct = secondsToAct;
        CostToRoll = costToRoll;
        CostToReroll = costToReroll;
    }
}
