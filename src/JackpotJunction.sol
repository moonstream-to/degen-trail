// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC1155} from "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Jackpot Junction game contract
/// @author Moonstream Engineering (engineering@moonstream.to)
///
/// @notice This is the game contract for The Degen Trail: Jackpot Junction, a game in world of The Degen Trail.
contract JackpotJunction is ERC1155, ReentrancyGuard {
    // Cumulative mass functions for probability distributions. Total mass for each distribution is 2^20 = 1048576.
    uint256[5] public UnmodifiedOutcomesCumulativeMass = [
        524288,
        524288 + 408934,
        524288 + 408934 + 104857,
        524288 + 408934 + 104857 + 10487,
        524288 + 408934 + 104857 + 10487 + 10
    ];
    uint256[5] public ImprovedOutcomesCumulativeMass = [
        469283,
        469283 + 408934,
        469283 + 408934 + 154857,
        469283 + 408934 + 154857 + 15487,
        469283 + 408934 + 154857 + 15487 + 15
    ];

    // How many blocks a player has to act (reroll/accept).
    uint256 public BlocksToAct;

    // The block number of the last roll/re-roll by the player.
    mapping(address => uint256) public LastRollBlock;

    // Costs (finest denomination of native token on the chain) to roll and reroll.
    uint256 public CostToRoll;
    uint256 public CostToReroll;

    // Item types: 0 (wagon cover), 1 (wagon body), 2 (wagon wheel), 3 (beast)
    // Terrain types: 0 (plain), 1 (forest), 2 (swamp), 3 (water), 4 (mountain), 5 (desert), 6 (ice)
    // Encoding of ERC1155 pool IDs: tier*28 + terrainType*4 + itemType
    // itemType => terrainType => tier
    mapping(uint256 => mapping(uint256 => uint256)) public CurrentTier;

    /// EquippedCover indicates the poolID of the cover that is currently equipped by the given player.
    /// The mapping is address(player) => poolID + 1.
    /// The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.
    mapping(address => uint256) public EquippedCover;
    /// EquippedBody indicates the poolID of the body that is currently equipped by the given player.
    /// The mapping is address(player) => poolID + 1.
    /// The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.
    mapping(address => uint256) public EquippedBody;
    /// EquippedWheels indicates the poolID of the wheels that are currently equipped by the given player.
    /// The mapping is address(player) => poolID + 1.
    /// The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.
    mapping(address => uint256) public EquippedWheels;
    /// EquippedBeasts indicates the poolID of the beasts that are currently equipped by the given player.
    /// The mapping is address(player) => poolID + 1.
    /// The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.
    mapping(address => uint256) public EquippedBeasts;

    event TierUnlocked(uint256 indexed itemType, uint256 indexed terrainType, uint256 indexed tier, uint256 poolID);
    event Roll(address indexed player);
    event Award(address indexed player, uint256 indexed outcome, uint256 value);

    error DeadlineExceeded();
    error WaitForTick();
    error InsufficientValue();
    error InvalidItem(uint256 poolID);
    error InsufficientItems(uint256 poolID);

    constructor(uint256 blocksToAct, uint256 costToRoll, uint256 costToReroll)
        ERC1155("https://github.com/moonstream-to/degen-trail")
    {
        BlocksToAct = blocksToAct;
        CostToRoll = costToRoll;
        CostToReroll = costToReroll;

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                emit TierUnlocked(i, j, 0, 4 * j + i);
            }
        }
    }

    receive() external payable {}

    function genera(uint256 poolID) public pure returns (uint256 itemType, uint256 terrainType, uint256 tier) {
        tier = poolID / 28;
        terrainType = (poolID % 28) / 4;
        itemType = poolID % 4;
    }

    function hasBonus(address degenerate) public view returns (bool bonus) {
        bonus = false;

        uint256 wagonCover = EquippedCover[degenerate];
        uint256 wagonBody = EquippedBody[degenerate];
        uint256 wheels = EquippedWheels[degenerate];
        uint256 beastTrain = EquippedBeasts[degenerate];

        if (wagonCover != 0 && wagonBody != 0 && wheels != 0 && beastTrain != 0) {
            uint256 terrainType;

            uint256 currentItemType;
            uint256 currentTier;
            uint256 currentTerrainType;

            (currentItemType, currentTerrainType, currentTier) = genera(wagonCover);
            if (CurrentTier[currentItemType][currentTerrainType] == currentTier) {
                bonus = true;
            }
            terrainType = currentTerrainType;

            if (bonus) {
                (currentItemType, currentTerrainType, currentTier) = genera(wagonBody);
                if (CurrentTier[currentItemType][currentTerrainType] != currentTier || currentTerrainType != terrainType) {
                    bonus = false;
                }
            }

            if (bonus) {
                (currentItemType, currentTerrainType, currentTier) = genera(wheels);
                if (CurrentTier[currentItemType][currentTerrainType] != currentTier || currentTerrainType != terrainType) {
                    bonus = false;
                }
            }

            if (bonus) {
                (currentItemType, currentTerrainType, currentTier) = genera(beastTrain);
                if (CurrentTier[currentItemType][currentTerrainType] != currentTier || currentTerrainType != terrainType) {
                    bonus = false;
                }
            }
        }
    }

    function sampleUnmodifiedOutcomeCumulativeMass(uint256 entropy) public view returns (uint256) {
        uint256 sample = entropy << 236 >> 236;
        if (sample < UnmodifiedOutcomesCumulativeMass[0]) {
            return 0;
        } else if (sample < UnmodifiedOutcomesCumulativeMass[1]) {
            return 1;
        } else if (sample < UnmodifiedOutcomesCumulativeMass[2]) {
            return 2;
        } else if (sample < UnmodifiedOutcomesCumulativeMass[3]) {
            return 3;
        }
        return 4;
    }

    function sampleImprovedOutcomesCumulativeMass(uint256 entropy) public view returns (uint256) {
        uint256 sample = entropy << 236 >> 236;
        if (sample < ImprovedOutcomesCumulativeMass[0]) {
            return 0;
        } else if (sample < ImprovedOutcomesCumulativeMass[1]) {
            return 1;
        } else if (sample < ImprovedOutcomesCumulativeMass[2]) {
            return 2;
        } else if (sample < ImprovedOutcomesCumulativeMass[3]) {
            return 3;
        }
        return 4;
    }

    function roll() external payable {
        uint256 requiredFee = CostToRoll;
        if (block.number <= LastRollBlock[msg.sender] + BlocksToAct) {
            requiredFee = CostToReroll;
        }

        if (msg.value < requiredFee) {
            revert InsufficientValue();
        }

        LastRollBlock[msg.sender] = block.number;

        emit Roll(msg.sender);
    }

    function _entropy(address degenerate) internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encode(blockhash(LastRollBlock[degenerate]), degenerate)));
    }

    function outcome(address degenerate, bool bonus) public view returns (uint256, uint256, uint256) {
        if (block.number <= LastRollBlock[degenerate]) {
            revert WaitForTick();
        }

        if (block.number > LastRollBlock[degenerate] + BlocksToAct) {
            revert DeadlineExceeded();
        }

        // entropy layout:
        // |- 118 bits -|- 118 bits -|- 20 bits -|
        //    item type  terrain type   outcome
        uint256 entropy = _entropy(degenerate);

        uint256 _outcome;
        if (bonus) {
            _outcome = sampleImprovedOutcomesCumulativeMass(entropy);
        } else {
            _outcome = sampleUnmodifiedOutcomeCumulativeMass(entropy);
        }

        uint256 value;

        if (_outcome == 1) {
            uint256 terrainType = (entropy << 118 >> 138) % 7;
            uint256 itemType = (entropy >> 138) % 4;
            value = 4 * terrainType + itemType;
        } else if (_outcome == 2) {
            value = CostToRoll + (CostToRoll >> 1);
            if (value > address(this).balance >> 6) {
                value = address(this).balance >> 6;
            }
        } else if (_outcome == 3) {
            value = address(this).balance >> 6;
        } else if (_outcome == 4) {
            value = address(this).balance >> 1;
        }

        return (entropy, _outcome, value);
    }

    function _award(uint256 _outcome, uint256 value) internal {
        if (_outcome == 1) {
            _mint(msg.sender, value, 1, "");
        } else if (_outcome == 2 || _outcome == 3 || _outcome == 4) {
            payable(msg.sender).transfer(value);
        }

        emit Award(msg.sender, _outcome, value);
    }

    function _clearRoll() internal {
        LastRollBlock[msg.sender] = 0;
    }

    function accept() external nonReentrant returns (uint256, uint256, uint256) {
        (uint256 entropy, uint256 _outcome, uint256 value) = outcome(msg.sender, hasBonus(msg.sender));
        _award(_outcome, value);
        _clearRoll();
        return (entropy, _outcome, value);
    }

    function equip(uint256[] calldata poolIDs) external nonReentrant {
        // TODO: Should only be callable if player is not currently rolling.
        for (uint256 i = 0; i < poolIDs.length; i++) {
            (uint256 itemType,,) = genera(poolIDs[i]);
            if (itemType == 0) {
                uint256 currentPoolID;
                if (EquippedCover[msg.sender] != 0) {
                    currentPoolID = EquippedCover[msg.sender] - 1;
                    _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
                }
                _safeTransferFrom(msg.sender, address(this), poolIDs[i], 1, "");
                EquippedCover[msg.sender] = poolIDs[i] + 1;
            } else if (itemType == 1) {
                uint256 currentPoolID;
                if (EquippedBody[msg.sender] != 0) {
                    currentPoolID = EquippedBody[msg.sender] - 1;
                    _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
                }
                _safeTransferFrom(msg.sender, address(this), poolIDs[i], 1, "");
                EquippedBody[msg.sender] = poolIDs[i] + 1;
            } else if (itemType == 2) {
                uint256 currentPoolID;
                if (EquippedWheels[msg.sender] != 0) {
                    currentPoolID = EquippedWheels[msg.sender] - 1;
                    _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
                }
                _safeTransferFrom(msg.sender, address(this), poolIDs[i], 1, "");
                EquippedWheels[msg.sender] = poolIDs[i] + 1;
            } else if (itemType == 3) {
                uint256 currentPoolID;
                if (EquippedBeasts[msg.sender] != 0) {
                    currentPoolID = EquippedBeasts[msg.sender] - 1;
                    _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
                }
                _safeTransferFrom(msg.sender, address(this), poolIDs[i], 1, "");
                EquippedBeasts[msg.sender] = poolIDs[i] + 1;
            } else {
                // If you end up in this branch, there's a bug in "genera".
                revert InvalidItem(poolIDs[i]);
            }
        }
    }

    function unequip() external nonReentrant {
        // TODO: Should only be callable if player is not currently rolling.
        uint256 currentPoolID;
        if (EquippedCover[msg.sender] != 0) {
            currentPoolID = EquippedCover[msg.sender] - 1;
            _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
            delete EquippedCover[msg.sender];
        }

        if (EquippedBody[msg.sender] != 0) {
            currentPoolID = EquippedBody[msg.sender] - 1;
            _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
            delete EquippedBody[msg.sender];
        }

        if (EquippedWheels[msg.sender] != 0) {
            currentPoolID = EquippedWheels[msg.sender] - 1;
            _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
            delete EquippedWheels[msg.sender];
        }

        if (EquippedBeasts[msg.sender] != 0) {
            currentPoolID = EquippedBeasts[msg.sender] - 1;
            _safeTransferFrom(address(this), msg.sender, currentPoolID, 1, "");
            delete EquippedBeasts[msg.sender];
        }
    }

    function craft(uint256 poolID, uint256 numOutputs) external nonReentrant returns (uint256 newPoolID) {
        if (balanceOf(msg.sender, poolID) < 2 * numOutputs) {
            revert InsufficientItems(poolID);
        }

        newPoolID = poolID + 28;

        _burn(msg.sender, poolID, 2 * numOutputs);
        _mint(msg.sender, newPoolID, numOutputs, "");

        (uint256 itemType, uint256 terrainType, uint256 tier) = genera(newPoolID);
        if (CurrentTier[itemType][terrainType] < tier) {
            CurrentTier[itemType][terrainType] = tier;
            emit TierUnlocked(itemType, terrainType, tier, newPoolID);
        }
    }

    function burn(uint256 poolID, uint256 amount) external {
        _burn(msg.sender, poolID, amount);
    }

    function burnBatch(uint256[] memory poolIDs, uint256[] memory amounts) external {
        _burnBatch(msg.sender, poolIDs, amounts);
    }
}
