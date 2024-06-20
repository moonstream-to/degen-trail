// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/JackpotJunction.sol";

contract TestableJackpotJunction is JackpotJunction {
    uint256 public Entropy;

    constructor(uint256 blocksToAct, uint256 costToRoll, uint256 costToReroll)
        JackpotJunction(blocksToAct, costToRoll, costToReroll)
    {}

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
    uint256 costToReroll = 25e16;

    function setUp() public {
        game = new JackpotJunction(blocksToAct, costToRoll, costToReroll);
    }

    function test_deployment() public {
        vm.assertEq(game.BlocksToAct(), blocksToAct);
        vm.assertEq(game.CostToRoll(), costToRoll);
        vm.assertEq(game.CostToReroll(), costToReroll);

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 7; j++) {
                vm.assertEq(game.CurrentTier(i, j), 0);
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
                vm.assertEq(itemType, i);
                vm.assertEq(terrainType, j);
                vm.assertEq(tier, 0);
            }
        }

        (itemType, terrainType, tier) = game.genera(95 * 28 + 4 * 3 + 2);
        vm.assertEq(itemType, 2);
        vm.assertEq(terrainType, 3);
        vm.assertEq(tier, 95);
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
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(0), 0);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524287), 0);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288), 1);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408933), 1);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934), 2);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104856), 2);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857), 3);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10486), 3);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487), 4);
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487 + 9), 4);
        // Overflow
        vm.assertEq(game.sampleUnmodifiedOutcomeCumulativeMass(524288 + 408934 + 104857 + 10487 + 10), 0);

        // Improved
        // uint256[5] public ImprovedOutcomesCumulativeMass = [
        //     469283,
        //     469283 + 408934,
        //     469283 + 408934 + 154857,
        //     469283 + 408934 + 154857 + 15487,
        //     469283 + 408934 + 154857 + 15487 + 15
        // ];
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(0), 0);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469282), 0);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283), 1);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408933), 1);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934), 2);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154856), 2);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857), 3);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15486), 3);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487), 4);
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487 + 14), 4);
        // Overflow
        vm.assertEq(game.sampleImprovedOutcomesCumulativeMass(469283 + 408934 + 154857 + 15487 + 15), 0);
    }

    function test_fund_game() public {
        vm.startPrank(player1);

        vm.deal(player1, 1 ether);

        payable(address(game)).transfer(1 ether);
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
        vm.assertEq(player1.balance, 0);
        vm.assertEq(address(game).balance, costToRoll);

        vm.roll(block.number + 1);
        vm.deal(player1, costToReroll);
        game.roll{value: costToReroll}();
        vm.assertEq(player1.balance, 0);
        vm.assertEq(address(game).balance, costToRoll + costToReroll);
    }

    function test_reroll_cost_not_applied_after_block_deadline() public {
        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct() + 1);

        vm.expectRevert(JackpotJunction.InsufficientValue.selector);
        vm.assertLt(costToReroll, costToRoll);
        game.roll{value: costToReroll}();

        vm.assertEq(player1.balance, 999 * costToRoll);
    }

    function test_reroll_cost_applied_at_block_deadline() public {
        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();

        vm.roll(block.number + game.BlocksToAct());

        game.roll{value: costToReroll}();

        vm.assertEq(player1.balance, 999 * costToRoll - costToReroll);
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

        uint256 hash = uint256(blockhash(block.number - game.BlocksToAct()));
        uint256 expectedEntropy = uint256(keccak256(abi.encode(blockhash(block.number - game.BlocksToAct()), player1)));
        (uint256 entropy,,) = game.outcome(player1, false);
        vm.assertNotEq(entropy, hash);
        vm.assertEq(entropy, expectedEntropy);
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
    uint256 costToReroll = 25e16;

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

    function test_reroll_cost_not_applied_after_acceptance() public {
        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), 1000000 ether);

        game.roll{value: costToRoll}();
        vm.roll(block.number + game.BlocksToAct());
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.accept();

        vm.assertLt(costToReroll, costToRoll);
        vm.roll(block.number + 1);

        vm.expectRevert(JackpotJunction.InsufficientValue.selector);
        game.roll{value: costToReroll}();

        game.roll{value: costToRoll}();
    }

    function test_nothing_then_item() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), 1000000 ether);

        vm.expectEmit();
        emit Roll(player1);
        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 0);
        vm.assertEq(actualValue, 0);

        vm.expectEmit();
        emit Roll(player1);
        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        uint256 itemType = 1;
        uint256 terrainType = 2;
        game.setEntropy((itemType << 138) + (terrainType << 20) + game.UnmodifiedOutcomesCumulativeMass(0));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 1);
        vm.assertEq(actualValue, 4 * terrainType + itemType);

        vm.assertEq(game.balanceOf(player1, 4 * terrainType + itemType), 0);

        vm.expectEmit();
        emit Award(player1, 1, 4 * terrainType + itemType);
        (actualEntropy, actualOutcome, actualValue) = game.accept();
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 1);
        vm.assertEq(actualValue, 4 * terrainType + itemType);

        vm.assertEq(game.balanceOf(player1, 4 * terrainType + itemType), 1);
    }

    function test_nothing_then_small_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 0);
        vm.assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(1));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 2);
        vm.assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        vm.assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 2);
        vm.assertEq(actualValue, game.CostToRoll() + (game.CostToRoll() >> 1));

        vm.assertEq(
            address(game).balance,
            initialGameBalance + game.CostToRoll() + game.CostToReroll()
                - (game.CostToRoll() + (game.CostToRoll() >> 1))
        );
        vm.assertEq(player1.balance, 1000 * game.CostToRoll() + (game.CostToRoll() >> 1) - game.CostToReroll());
    }

    function test_nothing_then_medium_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 0);
        vm.assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(2));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 3);
        vm.assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        vm.assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 3);
        vm.assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6);

        vm.assertEq(
            address(game).balance,
            initialGameBalance + game.CostToRoll() + game.CostToReroll()
                - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 6)
        );
        vm.assertEq(player1.balance, 999 * game.CostToRoll() - game.CostToReroll() + actualValue);
    }

    function test_nothing_then_large_reward() public {
        uint256 actualEntropy;
        uint256 actualOutcome;
        uint256 actualValue;

        uint256 initialGameBalance = 1000000 ether;

        vm.startPrank(player1);
        vm.deal(player1, 1000 * costToRoll);
        vm.deal(address(game), initialGameBalance);

        game.roll{value: costToRoll}();

        vm.roll(block.number + 1);
        game.setEntropy(0);
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 0);
        vm.assertEq(actualValue, 0);

        game.roll{value: costToReroll}();

        vm.roll(block.number + 1);
        game.setEntropy(game.UnmodifiedOutcomesCumulativeMass(3));
        (actualEntropy, actualOutcome, actualValue) = game.outcome(player1, false);
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 4);
        vm.assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        vm.assertEq(address(game).balance, initialGameBalance + game.CostToRoll() + game.CostToReroll());

        (actualEntropy, actualOutcome, actualValue) = game.accept();
        vm.assertEq(actualEntropy, game.Entropy());
        vm.assertEq(actualOutcome, 4);
        vm.assertEq(actualValue, (initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1);

        vm.assertEq(
            address(game).balance,
            initialGameBalance + game.CostToRoll() + game.CostToReroll()
                - ((initialGameBalance + game.CostToRoll() + game.CostToReroll()) >> 1)
        );
        vm.assertEq(player1.balance, 999 * game.CostToRoll() - game.CostToReroll() + actualValue);
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
                vm.assertEq(game.CurrentTier(i, j), 0);
                vm.expectEmit();
                emit TierUnlocked(i, j, 1, outputPoolID);
                game.craft(inputPoolID, 1);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                vm.assertEq(terminalInputBalance, initialInputBalance - 2);
                vm.assertEq(terminalOutputBalance, initialOutputBalance + 1);
                vm.assertEq(game.CurrentTier(i, j), 1);
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
                vm.assertEq(game.CurrentTier(i, j), 0);
                vm.expectEmit();
                emit TierUnlocked(i, j, 1, outputPoolID);
                game.craft(inputPoolID, numOutputs);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                vm.assertEq(terminalInputBalance, initialInputBalance - 2 * numOutputs);
                vm.assertEq(terminalOutputBalance, initialOutputBalance + numOutputs);
                vm.assertEq(game.CurrentTier(i, j), 1);
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
                vm.assertEq(game.CurrentTier(i, j), 92384);
                vm.expectEmit();
                emit TierUnlocked(i, j, 92385, outputPoolID);
                game.craft(inputPoolID, 1);
                uint256 terminalInputBalance = game.balanceOf(player2, inputPoolID);
                uint256 terminalOutputBalance = game.balanceOf(player2, outputPoolID);
                vm.assertEq(terminalInputBalance, initialInputBalance - 2);
                vm.assertEq(terminalOutputBalance, initialOutputBalance + 1);
                vm.assertEq(game.CurrentTier(i, j), 92385);
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
                game.mint(player2, inputPoolID, 2 * numOutputs - 1);
                vm.expectRevert(abi.encodeWithSelector(JackpotJunction.InsufficientItems.selector, inputPoolID));
                game.craft(inputPoolID, numOutputs);
            }
        }
    }

    function test_hasBonus() public {
        uint256 coverPlainsTier = game.CurrentTier(0, 0);
        uint256 bodyPlainsTier = game.CurrentTier(1, 0);
        uint256 wheelsPlainsTier = game.CurrentTier(2, 0);
        uint256 beastsPlainsTier = game.CurrentTier(3, 0);

        vm.startPrank(player2);

        // Make it so that even if the test blockchain is at a low block number, the game doesn't think
        // that it is waiting for the player to act.
        vm.roll(block.number + game.BlocksToAct());
        vm.assertGt(block.number, game.LastRollBlock(player2) + game.BlocksToAct());
        game.unequip();

        vm.assertFalse(game.hasBonus(player2));

        game.mint(player2, coverPlainsTier*28, 1);
        game.mint(player2, bodyPlainsTier*28 + 1, 1);
        game.mint(player2, wheelsPlainsTier*28 + 2, 1);
        game.mint(player2, beastsPlainsTier*28 + 3, 1);

        vm.assertGt(game.balanceOf(player2, coverPlainsTier*28), 1);
        vm.assertGt(game.balanceOf(player2, bodyPlainsTier*28 + 1), 1);
        vm.assertGt(game.balanceOf(player2, wheelsPlainsTier*28 + 2), 1);
        vm.assertGt(game.balanceOf(player2, beastsPlainsTier*28 + 3), 1);

        uint256[] memory equipArgs = new uint256[](4);
        equipArgs[0] = coverPlainsTier*28;
        equipArgs[1] = bodyPlainsTier*28 + 1;
        equipArgs[2] = wheelsPlainsTier*28 + 2;
        equipArgs[3] = beastsPlainsTier*28 + 3;
        game.equip(equipArgs);

        vm.assertEq(game.EquippedCover(player2), coverPlainsTier*28 + 1);
        vm.assertEq(game.EquippedBody(player2), bodyPlainsTier*28 + 1 + 1);
        vm.assertEq(game.EquippedWheels(player2), wheelsPlainsTier*28 + 2 + 1);
        vm.assertEq(game.EquippedBeasts(player2), beastsPlainsTier*28 + 3 + 1);

        vm.assertTrue(game.hasBonus(player2));

        game.mint(player2, coverPlainsTier*28 + 28, 1);
        game.mint(player2, bodyPlainsTier*28 + 1 + 28, 1);
        game.mint(player2, wheelsPlainsTier*28 + 2 + 28, 1);
        game.mint(player2, beastsPlainsTier*28 + 3 + 28, 1);

        vm.assertEq(game.CurrentTier(0, 0), coverPlainsTier + 1);
        vm.assertEq(game.CurrentTier(1, 0), bodyPlainsTier + 1);
        vm.assertEq(game.CurrentTier(2, 0), wheelsPlainsTier + 1);
        vm.assertEq(game.CurrentTier(3, 0), beastsPlainsTier + 1);

        vm.assertFalse(game.hasBonus(player2));

        equipArgs[0] = coverPlainsTier*28 + 28;
        equipArgs[1] = bodyPlainsTier*28 + 1 + 28;
        equipArgs[2] = wheelsPlainsTier*28 + 2 + 28;
        equipArgs[3] = beastsPlainsTier*28 + 3 + 28;
        game.equip(equipArgs);

        vm.assertEq(game.EquippedCover(player2), coverPlainsTier*28 + 28 + 1);
        vm.assertEq(game.EquippedBody(player2), bodyPlainsTier*28 + 1 + 28 + 1);
        vm.assertEq(game.EquippedWheels(player2), wheelsPlainsTier*28 + 2 + 28 + 1);
        vm.assertEq(game.EquippedBeasts(player2), beastsPlainsTier*28 + 3 + 28 + 1);

        vm.assertTrue(game.hasBonus(player2));

        vm.stopPrank();
    }
}
