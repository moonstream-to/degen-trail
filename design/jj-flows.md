# Jackpot Junction player flows

This document describes the player flows on the `JackpotJunction` smart contract, with reference to
the smart contract functions which enable each flow.

The flows are described from the point of view of the player:
1. [Rolling and rerolling](#roll-and-reroll)
1. [Block countdown](#block-countdown)
1. [Preview outcome](#preview-outcome)
1. Accept or abandon the outcome of a roll
1. Check whether you are rolling from the bonus wheel
1. View which items you have equipped
1. Equip items
1. Unequip items
1. Craft items

## Roll and reroll

A player can roll or reroll by calling the [`roll`](../docs/src/src/JackpotJunction.sol/contract.JackpotJunction.md#roll) method:

```
    function roll() external payable {};
```

This method is `payable`, and any calls to it will fail unless the player sends sufficient value
with their call.

If the player is initiating a sequence of actions, then they must pay the `CostToRoll`. If a player
initiated a sequence of actions (by calling `roll`), then they must take their next action within `BlocksToAct`.
If they fail to do so, they must `roll` again at the full `CostToRoll`. If the player has already initiated
a sequence of rolls and they are acting within `BlocksToAct` of their last action, then they must pay `CostToReroll`.

All these parameters are exposed as contract methods:

```
	// Selector: be59cce3
	function BlocksToAct() external view returns (uint256);
	// Selector: b870fe80
	function CostToReroll() external view returns (uint256);
	// Selector: 50b8aa92
	function CostToRoll() external view returns (uint256);
```

If the player sends *more* than the amount that the game requires them to send in order to roll, the extra
value remains on the contract.

## Block countdown

Once a player calls `roll`, they have a number of blocks in which to act. This number is specified by
the `BlocksToAct()` method on the game contract.

The player can view the block at which they last rolled using:

```
	// Selector: 9a0facc2
	function LastRollBlock(address ) external view returns (uint256);
```

Given a `game` contract, a given `player` can continue a sequence of actions (by either rolling or
accepting the outcome of their previous roll) as long as the current `block.number` satisfies:

```
block.number <= game.LastRollBlock(player) + game.BlocksToAct();
```

Equivalently, a game client could display a block countdown to a player using:

```
game.LastRollBlock(player) + game.BlocksToAct() - block.number;
```

## Preview outcome

The way that Jackpot Junction is designed, a player is able to see the outcome of their roll before
they choose to accept or reject it.

To preview the outcome of their previous roll (assuming that their block deadline has not passed), they
can call the following `view` method:

```
	// Selector: 3a259e6a
	function outcome(address degenerate, bool bonus) external view returns (uint256, uint256, uint256);
```

