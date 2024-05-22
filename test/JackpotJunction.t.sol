// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/JackpotJunction.sol";

contract TestableJackpotJunction is JackpotJunction {
    uint256 public Entropy;

    constructor(uint256 blocksToAct, uint256 costToRoll, uint256 costToReroll) JackpotJunction(blocksToAct, costToRoll, costToReroll) {}

    function setEntropy(uint256 value) public {
        Entropy = value;
    }

    function _entropy(address) internal view override returns (uint256) {
        return Entropy;
    }

    function mint(address to, uint256 poolID, uint256 amount) public {
        _mint(to, poolID, amount, "");
        uint256 itemType;
        uint256 tier;
        uint256 terrainType;
        (itemType, terrainType, tier) = genera(poolID);

        if (CurrentTier[itemType][terrainType] < tier) {
            CurrentTier[itemType][terrainType] = tier;
        }
    }
}

contract JackpotJunctionTest is Test {
    event Roll(address indexed player);

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

        vm.expectEmit();
        emit Roll(player1);
        game.roll{value: costToRoll}();
        assertEq(player1.balance, 0);
        assertEq(address(game).balance, costToRoll);

        vm.roll(block.number + 1);
        vm.deal(player1, costToReroll);
        game.roll{value: costToReroll}();
        assertEq(player1.balance, 0);
        assertEq(address(game).balance, costToRoll + costToReroll);
    }

    function test_reroll_cost_not_applied_after_block_deadline() public {
        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct() + 1);

        vm.expectRevert(JackpotJunction.InsufficientValue.selector);
        assertLt(costToReroll, costToRoll);
        game.roll{value: costToReroll}();

        assertEq(player1.balance, 999*costToRoll);
    }

    function test_reroll_cost_applied_at_block_deadline() public {
        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct());

        game.roll{value: costToReroll}();

        assertEq(player1.balance, 999*costToRoll - costToReroll);
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
    event Roll(address indexed player);
    event TierUnlocked(uint256 indexed itemType, uint256 indexed terrainType, uint256 indexed tier, uint256 poolID);
    event Award(address indexed player, uint256 indexed outcome, uint256 value);

    TestableJackpotJunction game;

    uint256 deployerPrivateKey = 0x42;
    address deployer = vm.addr(deployerPrivateKey);

    // New player, no items
    uint256 player1PrivateKey = 0x13371;
    address player1 = vm.addr(player1PrivateKey);

    // Player who has high tier items
    uint256 player2PrivateKey = 0x13372;
    address player2 = vm.addr(player2PrivateKey);

    uint256 blocksToAct = 10;
    uint256 costToRoll = 1e18;
    uint256 costToReroll = 4e17;

    function setUp() public {
        game = new TestableJackpotJunction(blocksToAct, costToRoll, costToReroll);

        // Mint player2 one of each tier 0 item.
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                game.mint(player2, 4 * j + i, 1);
            }
        }
    }

    function test_accept_reverts_after_deadline() public {
        vm.startPrank(player1);

        vm.deal(player1, 1000 * costToRoll);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct() + 1);
        vm.expectRevert(JackpotJunction.DeadlineExceeded.selector);
        game.accept();
    }

    function test_accept_with_cards_reverts_after_deadline() public {
        vm.startPrank(player1);

        vm.deal(player1, 1000 * costToRoll);

        game.roll{value: costToRoll}();

        for (uint256 i = 0; i < 4; i++) {
            game.mint(player1, i, 1);
        }

        vm.roll(block.number + game.BlocksToAct() + 1);
        vm.expectRevert(JackpotJunction.DeadlineExceeded.selector);
        game.acceptWithCards(0, 1, 2, 3);
    }

    function test_nothing_then_item() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), 1000000 ether);

        vm.expectEmit();
        emit Roll(player1);
        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        vm.expectEmit();
        emit Roll(player1);
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

        vm.expectEmit();
        emit Award(player1, 1, 4*terrainType + itemType);
        (actualEntropy, actualOutcome, actualValue) = game.accept();
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 1);
        assertEq(actualValue, 4*terrainType + itemType);

        assertEq(game.balanceOf(player1, 4*terrainType + itemType), 1);
    }

    function test_nothing_then_small_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(1));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 2);
        assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 2);
        assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - (game.CostToRoll() + (game.CostToRoll() >> 1)));
        assertEq(player1.balance, 1000*game.CostToRoll() + (game.CostToRoll() >> 1) - game.CostToReroll());
    }

    function test_nothing_then_medium_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(2));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 3);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 3);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6));
        assertEq(player1.balance, 999*game.CostToRoll()- game.CostToReroll() + actualValue);
    }

    function test_nothing_then_large_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(3));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 4);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 4);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1));
        assertEq(player1.balance, 999*game.CostToRoll()- game.CostToReroll() + actualValue);
    }

    function test_bonus_nothing_then_item() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        uint256 itemType = 1;
        uint256 terrainType = 2;
        game.setEntropy((itemType << 138) + (terrainType << 20) + game.ImprovedOutcomesCumulativeMass(0));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 1);
        assertEq(actualValue, 4*terrainType + itemType);

        assertEq(game.balanceOf(player2, 4*terrainType + itemType), 1);

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 1);
        assertEq(actualValue, 4*terrainType + itemType);

        assertEq(game.balanceOf(player2, 4*terrainType + itemType), 2);
    }

    function test_bonus_nothing_then_small_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.ImprovedOutcomesCumulativeMass(1));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 2);
        assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 2);
        assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - (game.CostToRoll() + (game.CostToRoll() >> 1)));
        assertEq(player2.balance, 1000*game.CostToRoll() + (game.CostToRoll() >> 1) - game.CostToReroll());
    }

    function test_bonus_nothing_then_medium_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.ImprovedOutcomesCumulativeMass(2));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 3);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 3);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6));
        assertEq(player2.balance, 999*game.CostToRoll()- game.CostToReroll() + actualValue);
    }

    function test_bonus_nothing_then_large_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.ImprovedOutcomesCumulativeMass(3));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player2, true);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 4);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 4);
        assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll() - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1));
        assertEq(player2.balance, 999*game.CostToRoll()- game.CostToReroll() + actualValue);
    }

    function test_bonus_acceptance_fails_with_incorrect_item_types() public {
        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.ImprovedOutcomesCumulativeMass(3));

        vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InvalidItem.selector, 1));
        game.acceptWithCards(1, 0, 2, 3);

        vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InvalidItem.selector, 2));
        game.acceptWithCards(0, 2, 1, 3);

        vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InvalidItem.selector, 3));
        game.acceptWithCards(0, 1, 3, 2);

        vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InvalidItem.selector, 2));
        game.acceptWithCards(0, 1, 2, 2);

        assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());
        assertEq(player2.balance, 999*game.CostToRoll() - game.CostToReroll());
    }

    function test_bonus_is_not_applied_if_cover_is_not_max_tier() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();


        vm.roll(block.number + 1);
        game.mint(player1, 28, 1);

        assertEq(game.CurrentTier(0, 0), 1);
        assertEq(game.CurrentTier(1, 0), 0);
        assertEq(game.CurrentTier(2, 0), 0);
        assertEq(game.CurrentTier(3, 0), 0);

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_body_is_not_max_tier() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.mint(player1, 28 + 1, 1);

        assertEq(game.CurrentTier(0, 0), 0);
        assertEq(game.CurrentTier(1, 0), 1);
        assertEq(game.CurrentTier(2, 0), 0);
        assertEq(game.CurrentTier(3, 0), 0);

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_wheel_is_not_max_tier() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.mint(player1, 28 + 2, 1);

        assertEq(game.CurrentTier(0, 0), 0);
        assertEq(game.CurrentTier(1, 0), 0);
        assertEq(game.CurrentTier(2, 0), 1);
        assertEq(game.CurrentTier(3, 0), 0);

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_beast_is_not_max_tier() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.mint(player1, 28 + 3, 1);

        assertEq(game.CurrentTier(0, 0), 0);
        assertEq(game.CurrentTier(1, 0), 0);
        assertEq(game.CurrentTier(2, 0), 0);
        assertEq(game.CurrentTier(3, 0), 1);

        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_cover_of_different_terrain_type() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(4 + 0, 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_body_of_different_terrain_type() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 4 + 1, 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_wheel_of_different_terrain_type() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 4 + 2, 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_bonus_is_not_applied_if_beast_of_different_terrain_type() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player2);
        vm.deal(player2, 1000*costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        assertGe(game.UnmodifiedOutcomesCumulativeMass(0) - 1, game.ImprovedOutcomesCumulativeMass(0));
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(0) - 1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        (actualEntropy, actualOutcome, actualValue) = game.acceptWithCards(0, 1, 2, 4 + 3);
        assertEq(actualEntropy, game.Entropy());
        assertEq(actualOutcome, 0);
        assertEq(actualValue, 0);
    }

    function test_crafting_tier_0_to_tier_1() public {
        vm.startPrank(player2);
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                uint256 inputPoolID = 4 * j + i;
                uint256 outputPoolID = 28 + inputPoolID;
                game.mint(player2, inputPoolID, 2);
                uint256 initialInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 initialOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(game.CurrentTier(i, j), 0);
                vm.expectEmit();
                emit TierUnlocked(i, j, 1, outputPoolID);
                game.craft(inputPoolID, 1);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(terminalInputBalance, initialInputBalance - 2);
                assertEq(terminalOutputBalance, initialOutputBalance + 1);
                assertEq(game.CurrentTier(i, j), 1);
            }
        }
    }

    function test_crafting_tier_0_to_tier_1_193284_outputs() public {
        vm.startPrank(player2);
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                uint256 inputPoolID = 4 * j + i;
                uint256 outputPoolID = 28 + inputPoolID;
                uint256 numOutputs = 193284;
                game.mint(player2, inputPoolID, 2 * numOutputs);
                uint256 initialInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 initialOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(game.CurrentTier(i, j), 0);
                vm.expectEmit();
                emit TierUnlocked(i, j, 1, outputPoolID);
                game.craft(inputPoolID, numOutputs);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(terminalInputBalance, initialInputBalance - 2 * numOutputs);
                assertEq(terminalOutputBalance, initialOutputBalance + numOutputs);
                assertEq(game.CurrentTier(i, j), 1);
            }
        }
    }

    function test_crafting_tier_92384_to_tier_92385() public {
        vm.startPrank(player2);
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                uint256 inputPoolID = 92384 * 28 + 4 * j + i;
                uint256 outputPoolID = 28 + inputPoolID;
                game.mint(player2, inputPoolID, 2);
                uint256 initialInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 initialOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(game.CurrentTier(i, j), 92384);
                vm.expectEmit();
                emit TierUnlocked(i, j, 92385, outputPoolID);
                game.craft(inputPoolID, 1);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                assertEq(terminalInputBalance, initialInputBalance - 2);
                assertEq(terminalOutputBalance, initialOutputBalance + 1);
                assertEq(game.CurrentTier(i, j), 92385);
            }
        }
    }

    function test_crafting_fails_when_insufficient_zero_balance() public {
        vm.startPrank(player2);
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                uint256 inputPoolID = 92384 * 28 + 4 * j + i;
                game.burn(inputPoolID, game.balanceOf(player2, inputPoolID));
                vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InsufficientItems.selector, inputPoolID));
                game.craft(inputPoolID, 1);
            }
        }
    }

    function test_crafting_fails_when_insufficient_positive_balance() public {
        vm.startPrank(player2);
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                uint256 inputPoolID = 92384 * 28 + 4 * j + i;
                uint256 numOutputs = 19283498;
                game.burn(inputPoolID, game.balanceOf(player2, inputPoolID));
                game.mint(player2, inputPoolID, 2*numOutputs - 1);
                vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InsufficientItems.selector, inputPoolID));
                game.craft(inputPoolID, numOutputs);
            }
        }
    }
}
