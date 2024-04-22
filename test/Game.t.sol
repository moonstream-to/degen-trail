// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract DegenTrailTest is Test {
    DegenTrail game;

    uint256 blockDeadline = 10;
    uint256 rollFee = 10;
    uint256 rerollFee = 5;
    uint256 deploymentBlock;

    function setUp() public {
        deploymentBlock = block.number;
        game = new DegenTrail(blockDeadline, rollFee, rerollFee);
    }

    function test_hexp() public view {
        assertTrue(game.hexp(0, 0));
        assertFalse(game.hexp(0, 1));
        assertTrue(game.hexp(0, 2));
        assertFalse(game.hexp(1, 0));
        assertTrue(game.hexp(0, 198));
        assertTrue(game.hexp(1, 199));
        assertFalse(game.hexp(1, 200));
        assertFalse(game.hexp(0, 200));
        assertTrue(game.hexp(293842390844, 36));
        assertFalse(game.hexp(293842390845, 36));
        assertTrue(game.hexp(293842390845, 37));
        assertFalse(game.hexp(293842390844, 37));
    }

    function test_neighborsp() public view {
        assertTrue(game.neighborsp(0, 0, 1, 1));
        assertTrue(game.neighborsp(0, 0, 0, 2));
        assertFalse(game.neighborsp(0, 0, 2, 0));
        assertTrue(game.neighborsp(0, 2, 1, 1));
        assertTrue(game.neighborsp(0, 2, 1, 3));
        assertTrue(game.neighborsp(293408, 148, 293407, 147));
        assertTrue(game.neighborsp(293408, 148, 293407, 149));
        assertTrue(game.neighborsp(293408, 148, 293409, 149));
        assertTrue(game.neighborsp(293408, 148, 293409, 147));
        assertTrue(game.neighborsp(293408, 148, 293408, 146));
        assertTrue(game.neighborsp(293408, 148, 293408, 150));
    }

    function test_environment() public view {
        // i = 0: 0
        assertEq(game.environment(0), 0);
        // i = 27: 0
        assertEq(game.environment(27), 0);
        // i = 31: 0
        assertEq(game.environment(31), 0);

        // i = 3 * 32 + 5 = 101: 2
        assertEq(game.environment(101), 2);
        // i = 10 * 32 + 17 = 337: 2
        assertEq(game.environment(337), 2);

        // i = 256 + 64 + 32 + 9 = 361: 5
        assertEq(game.environment(361), 5);
    }

    function test_hex_state_in_column_0() public view {
        uint256[2][] memory indices = new uint256[2][](100);
        for (uint256 j = 0; j < 100; j++) {
            indices[j][0] = 0;
            indices[j][1] = 2*j;
        }

        uint256[3][] memory states = game.board(indices);


        uint256 priorBlockNumber = deploymentBlock;
        if (priorBlockNumber > 0) {
            priorBlockNumber -= 1;
        }
        uint256 startingEntropy = uint256(blockhash(priorBlockNumber)) >> 12 << 12;

        for (uint256 k = 0; k < 100; k++) {
            assertEq(states[k][0], 0);
            assertEq(states[k][1], 2*k);
            assertEq(states[k][2] % 2, 1);

            uint256 terrainType = states[k][2] >> 1;

            uint8 hexEntropy = uint8((startingEntropy + (31 * k)) & 0x7F);
            assertLt(hexEntropy, game.EnvironmentDistributions(0, terrainType));
            if (terrainType < 6) {
                assertGe(hexEntropy, game.EnvironmentDistributions(0, terrainType+1));
            }
        }
    }
}

