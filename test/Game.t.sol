// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract DegenTrailTest is Test {
    DegenTrail game;

    uint256 blockDeadline = 10;
    uint256 rollFee = 10;
    uint256 rerollFee = 5;

    function setUp() public {
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
        // j = 0: 0
        assertEq(game.environment(0), 0);
        // j = 27: 0
        assertEq(game.environment(27), 0);
        // j = 31: 0
        assertEq(game.environment(31), 0);

        // j = 3 * 32 + 5 = 101: 2
        assertEq(game.environment(101), 2);
        // j = 10 * 32 + 17 = 337: 2
        assertEq(game.environment(337), 2);

        // j = 256 + 64 + 32 + 9 = 361: 5
        assertEq(game.environment(361), 5);
    }
}

