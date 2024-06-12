# Jackpot Junction player flows

This document describes the player flows on the `JackpotJunction` smart contract, with reference to
the smart contract functions which enable each flow.

The flows are described from the point of view of the player:
1. [Rolling and rerolling](#roll-and-reroll)
1. [Block countdown](#block-countdown)
1. [Preview outcome](#preview-outcome)
1. [Accept or abandon the outcome of a roll](#accept-or-abandon-the-outcome-of-a-roll)
1. [Check whether you are rolling from the bonus wheel](#check-whether-you-are-rolling-from-the-bonus-wheel)
1. [View which items you have equipped](#view-which-items-you-have-equipped)
1. [Equip items](#equip-items)
1. [Unequip items](#unequip-items)
1. [Craft items](#craft-items)

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
can call the [`outcome`](../docs/src/src/JackpotJunction.sol/contract.JackpotJunction.md#outcome) `view` method:

```
	// Selector: 3a259e6a
	function outcome(address degenerate, bool bonus) external view returns (uint256, uint256, uint256);
```

A player can only view the outcome of their previous roll if:
1. At least one block has elapsed since their previous roll (i.e. `block.number > game.LastRollBlock(player)`).
This is because the game uses the hash of the block in which the roll was included as the randomness
used to compute the outcome of the roll.
1. The player has not exceeded the block deadline since their last roll (i.e. `block.number <= game.LastRollBlock(player) + game.BlocksToAct()`).

The `outcome` function takes two arguments:
1. `degenerate` - the player's address
2. `bonus` - set this to `false` if you want to sample the player's outcome from the unmodified probability distribution and to `true` if you want to sample their outcome from the
improved probability distribution. To check if a player's equipped items make it so that they are sampling from the improved distribution, see
[Check whether you are rolling from the bonus wheel](#check-whether-you-are-rolling-from-the-bonus-wheel).

The `outcome` function returns three `uint256` values:
1. `entropy`
1. `outcomeIndex`
1. `outcomeValue`

The `entropy` is the randomness that the game used to determine the outcome. This is returned for informational
purposes.

The `outcomeIndex` is constrained so that `0 <= outcomeIndex <= 4`:
0. Nothing - `outcomeValue` can be ignored
1. Player receives an item - `outcomeValue` is the `tokenID` of the item that the player would receive if they accepted the outcome
2. Player receives the consolation reward - `outcomeValue` is the amount of native token that would be transferred to the player if they accepted the outcome
3. Player receives a moderate reward - `outcomeValue` is the amount of native token that would be transferred to the player if they accepted the outcome
4. Player hit the jackpot - `outcomeValue` is the amount of native token that would be transferred to the player if they accepted the outcome

### See what a player will receive if they accept their last roll

```
game.outcome(player, game.hasBonus(player));
```

### See what a player would have received if they had top tier items in every slot

```
game.outcome(player, true);
```

## Accept or abandon the outcome of a roll

After a player has rolled, they can accept the outcome of their roll as long as:
1. At least 1 block has elapsed since they rolled
1. No more than `BlocksToAct()` blocks have elapsed since they rolled

They can *view* the outcome of the roll using the flow defined in [Preview outcome](#preview-outcome). If they are happy
with what they see, they can submit an `accept` transaction:

```
	// Selector: 2852b71c
	function accept() external  returns (uint256, uint256, uint256);
```

The return values of `accept` match the return values of [`outcome`](../docs/src/src/JackpotJunction.sol/contract.JackpotJunction.md#outcome).

If the player would prefer not to accept the outcome of their roll, they can either [`roll` again](#roll-and-reroll) or,
simply through inaction, they can abandon the current sequence of actions (i.e. leave the game).

If a player abandons their sequence of actions by not acting before their block deadline, they can always
come back and [`roll`](#roll-and-reroll) again for the full `CostToRoll()`.

## Check whether you are rolling from the bonus wheel

To determine whether or not `bonus` applies to a player, you can call the [`hasBonus`](../docs/src/src/JackpotJunction.sol/contract.JackpotJunction.md#hasbonus) method on the game contract:

```
	// Selector: b8f905c8
	function hasBonus(address degenerate) external view returns (bool bonus);
```

So, to calculate a player's bonus based on the items they currently have equipped (which is how the game determines whether or not the bonus applies to them):

```
game.outcome(player, game.hasBonus(player));
```

When making this call off-chain, you can specify the block number at which to execute this method. That would allow you
to show a history of past outcomes that the player may have been *eligible* to accept even if they didn't actually
accept them.

## View which items you have equipped

## Equip items

## Unequip items

## Craft items
