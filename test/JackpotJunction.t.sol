// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/JackpotJunction.sol";

contract JackpotJunctionTest is Test {
    JackpotJunction game;

    uint256 deployerPrivateKey = 0x42;
    address deployer = vm.addr(deployerPrivateKey);

    uint256 player1PrivateKey = 0x13371;
    address player1 = vm.addr(player1PrivateKey);

    uint256 player2PrivateKey = 0x13372;
    address player2 = vm.addr(player2PrivateKey);

    uint256 blocksToAct = 10;
    uint256 costToRoll = 1e18;
    uint256 costToReroll = 4e17;

    function setUp() public {
        game = new JackpotJunction(blocksToAct, costToRoll, costToReroll);
    }

    function test_deployment() public {
        assertEq(game.BlocksToAct(), blocksToAct);
        assertEq(game.CostToRoll(), costToRoll);
        assertEq(game.CostToReroll(), costToReroll);

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                assertEq(game.CurrentTier(i, j), 0);
            }
        }
    }

    function test_genera() public {
        uint256 itemType;
        uint256 terrainType;
        uint256 tier;

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                (itemType, terrainType, tier) = game.genera(4*j + i);
                assertEq(itemType, i);
                assertEq(terrainType, j);
                assertEq(tier, 0);
            }
        }

        (itemType, terrainType, tier) = game.genera(95*28 + 4*3 + 2);
        assertEq(itemType, 2);
        assertEq(terrainType, 3);
        assertEq(tier, 95);
    }
}
