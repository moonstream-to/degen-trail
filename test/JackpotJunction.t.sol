// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/JackpotJunction.sol";

contract JackpotJunctionWithControllableEntropy is JackpotJunction {
    uint256 public Entropy;

    constructor(uint256 blocksToAct, uint256 costToRoll, uint256 costToReroll) JackpotJunction(blocksToAct, costToRoll, costToReroll) {}

    function setEntropy(uint256 value) public {
        Entropy = value;
    }

    function _entropy(address) internal view override returns (uint256) {
        return Entropy;
    }
}

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
                (itemType, terrainType, tier) = game.genera(4 * j + i);
                assertEq(itemType, i);
                assertEq(terrainType, j);
                assertEq(tier, 0);
            }
        }

        (itemType, terrainType, tier) = game.genera(95 * 28 + 4 * 3 + 2);
        assertEq(itemType, 2);
        assertEq(terrainType, 3);
        assertEq(tier, 95);
    }

    function test_samples() public {
        // Unmodified
        // uint256[5] public UnmodifiedOutcomesCumulativeMass = [
        //     524288,
        //     524288 + 408934,
        //     524288 + 408934 + 104857,
        //     524288 + 408934 + 104857 + 10487,
        //     524288 + 408934 + 104857 + 10487 + 10
        // ];
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(0), 0);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524287), 0);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288), 1);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408933), 1);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934), 2);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104856), 2);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857), 3);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10486), 3);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487), 4);
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487 + 9), 4);
        // Overflow
        assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487 + 10), 0);

        // Improved
        // uint256[5] public ImprovedOutcomesCumulativeMass = [
        //     469283,
        //     469283 + 408934,
        //     469283 + 408934 + 154857,
        //     469283 + 408934 + 154857 + 15487,
        //     469283 + 408934 + 154857 + 15487 + 15
        // ];
        assertEq(game.sampleImprovedOutcomesCumulativeMass(0), 0);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469282), 0);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283), 1);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408933), 1);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934), 2);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154856), 2);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857), 3);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15486), 3);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487), 4);
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487 + 14), 4);
        // Overflow
        assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487 + 15), 0);
    }

    function test_roll() public {
        vm.startPrank(player1);

        vm.deal(player1, costToRoll);

        // Even if the player has enough balance, if they call the roll method without supplying that balance,
        // the game reverts.
        vm.expectRevert(JackpotJunction.InsufficientValue.selector);
        game.roll();

        game.roll{value: costToRoll}();
        assertEq(player1.balance, 0);
        assertEq(address(game).balance, costToRoll);

        vm.roll(block.number + 1);
        vm.deal(player1, costToReroll);
        game.roll{value: costToReroll}();
        assertEq(player1.balance, 0);
        assertEq(address(game).balance, costToRoll + costToReroll);
    }

    function test_outcome_reverts_before_tick() public {
        vm.startPrank(player1);

        vm.deal(player1, 1000 * costToRoll);

        game.roll{value: costToRoll}();

        vm.expectRevert(JackpotJunction.WaitForTick.selector);
        game.outcome(player1, false);
    }

    function test_outcome_reverts_after_deadline() public {
        vm.startPrank(player1);

        vm.deal(player1, 1000 * costToRoll);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct() + 1);
        vm.expectRevert(JackpotJunction.DeadlineExceeded.selector);
        game.outcome(player1, false);
    }

    function test_outcome() public {
        vm.startPrank(player1);

        vm.deal(player1, 1000 * costToRoll);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct());

        uint256 expectedEntropy = uint256(blockhash(block.number - game.BlocksToAct()));
        (uint256 entropy,,) = game.outcome(player1, false);
        assertEq(entropy, expectedEntropy);
    }
}

contract JackpotJunctionPlayTest is Test {
    JackpotJunctionWithControllableEntropy game;

    uint256 deployerPrivateKey = 0x42;
    address deployer = vm.addr(deployerPrivateKey);

    uint256 player1PrivateKey = 0x13371;
    address player1 = vm.addr(player1PrivateKey);

    uint256 blocksToAct = 10;
    uint256 costToRoll = 1e18;
    uint256 costToReroll = 4e17;

    function setUp() public {
        game = new JackpotJunctionWithControllableEntropy(blocksToAct, costToRoll, costToReroll);
    }

    function test_nothing_then_item() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        uint256 itemType = 1;
        uint256 terrainType = 2;
        game.setEntropy((itemType << 138) + (terrainType << 20) + game.UnmodifiedOutcomesCumulativeMass(0));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 1);
        assertEq(actualValue, 4*terrainType + itemType);

        assertEq(game.balanceOf(player1, 4*terrainType + itemType), 0);

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 1);
        assertEq(actualValue, 4*terrainType + itemType);

        assertEq(game.balanceOf(player1, 4*terrainType + itemType), 1);
    }
}
