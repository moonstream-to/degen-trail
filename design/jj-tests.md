# JackpotJunction Test Checklist

ChatGPT, based off of the [Jackpot Junction player flows document](./jj-flows.md), created a checklist
of necessary tests.

If a test is implemented, it is checked off and the name of the corresponding implementation in [`JackpotJunction.t.sol](../test/JackpotJunction.t.sol)
is included.

## Rolling and Rerolling
- [x] Test initial roll with sufficient funds (`test_roll`)
- [x] Test initial roll with insufficient funds (`test_roll_insufficient_funds`)
- [x] Test reroll with sufficient funds within block deadline (`test_reroll_cost_applied_at_block_deadline`)
- [x] Test reroll with insufficient funds within block deadline (`test_reroll_insufficient_funds`)
- [x] Test reroll with sufficient funds after block deadline (`test_reroll_cost_not_applied_after_block_deadline`)
- [x] Test roll failure due to ongoing roll sequence (`test_reroll_cost_not_applied_after_acceptance`)

## Block Countdown
- [ ] Test block countdown calculation
- [x] Test block countdown after rolling (`test_roll`)
- [x] Test block countdown after accepting outcome (`test_reroll_cost_not_applied_after_acceptance`)
- [x] Test block countdown expiration (`test_outcome_reverts_after_deadline`)

## Preview Outcome
- [x] Test preview outcome within valid block range (`test_outcome`)
- [x] Test preview outcome before next block (WaitForTick) (`test_outcome_reverts_before_tick`)
- [x] Test preview outcome after block deadline (DeadlineExceeded) (`test_outcome_reverts_after_deadline`)
- [x] Test preview outcome with bonus (`test_nothing_then_item_with_bonus`)
- [x] Test preview outcome without bonus (`test_nothing_then_item`)

## Accept or Abandon Outcome
- [x] Test accepting the outcome within block deadline (`test_nothing_then_item`)
- [x] Test accepting the outcome after block deadline (DeadlineExceeded) (`test_accept_reverts_after_deadline`)
- [x] Test abandoning the outcome by not acting before block deadline (`test_reroll_cost_not_applied_after_block_deadline`)

## Check Bonus Wheel Eligibility
- [x] Test bonus wheel eligibility with no items equipped (`test_hasBonus`)
- [x] Test bonus wheel eligibility with items equipped (`test_hasBonus`)
- [x] Test bonus wheel eligibility after equipping higher tier items (`test_hasBonus`)

## View Equipped Items
- [ ] Test viewing equipped items with no items equipped
- [ ] Test viewing equipped items with multiple items equipped
- [x] Test viewing equipped items after equipping and unequipping items (`test_unequip_items`)

## Equip Items
- [x] Test equipping a single item (`test_unequip_items`)
- [x] Test equipping multiple items (`test_equip_unequip_reequip_wheels`)
- [x] Test equipping multiple items with the same slot (`test_equip_multiple_items_with_duplicated_slot`)
- [x] Test equipping items and verify TransferSingle events (`test_equip_multiple_items_with_duplicated_slot`)

## Unequip Items
- [x] Test unequipping all items (`test_unequip_items`)
- [x] Test unequipping and re-equipping items (`test_equip_unequip_reequip_wheels`)

## Craft Items
- [x] Test crafting items with sufficient inputs (`test_crafting_tier_0_to_tier_1`)
- [x] Test crafting items with insufficient inputs (`test_crafting_fails_when_insufficient_zero_balance`)
- [x] Test crafting items and verify item pool ID update (`test_crafting_tier_0_to_tier_1`)
- [x] Test crafting items and verify TransferSingle events (`test_crafting_tier_0_to_tier_1`)
