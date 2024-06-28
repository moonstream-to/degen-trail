# JackpotJunction
[Git Source](https://github.com/moonstream-to/degen-trail/blob/54902d73c65c7678878504a329fd1306cb1d1d95/src/JackpotJunction.sol)

**Inherits:**
ERC1155, ReentrancyGuard

**Author:**
Moonstream Engineering (engineering@moonstream.to)

This is the game contract for The Degen Trail: Jackpot Junction, a game in world of The Degen Trail.


## State Variables
### UnmodifiedOutcomesCumulativeMass
Cumulative mass function for the unmodified distribution over outcomes.


```solidity
uint256[5] public UnmodifiedOutcomesCumulativeMass = [
    524288,
    524288 + 408934,
    524288 + 408934 + 104857,
    524288 + 408934 + 104857 + 10487,
    524288 + 408934 + 104857 + 10487 + 10
];
```


### ImprovedOutcomesCumulativeMass
Cumulative mass function for the improved distribution over outcomes.


```solidity
uint256[5] public ImprovedOutcomesCumulativeMass = [
    469283,
    469283 + 408934,
    469283 + 408934 + 154857,
    469283 + 408934 + 154857 + 15487,
    469283 + 408934 + 154857 + 15487 + 15
];
```


### BlocksToAct
How many blocks a player has to act (reroll/accept).


```solidity
uint256 public BlocksToAct;
```


### LastRollBlock
The block number of the last roll/re-roll by each player.


```solidity
mapping(address => uint256) public LastRollBlock;
```


### CostToRoll
Cost (finest denomination of native token on the chain) to roll.


```solidity
uint256 public CostToRoll;
```


### CostToReroll
Cost (finest denomination of native token on the chain) to reroll.


```solidity
uint256 public CostToReroll;
```


### CurrentTier
Specifies the largest tier that has been unlocked for a given (itemType, terrainType) pair.

Item types: 0 (wagon cover), 1 (wagon body), 2 (wagon wheel), 3 (beast)

Terrain types: 0 (plains), 1 (forest), 2 (swamp), 3 (water), 4 (mountain), 5 (desert), 6 (ice)

Encoding of ERC1155 pool IDs: tier*28 + terrainType*4 + itemType

itemType => terrainType => tier


```solidity
mapping(uint256 => mapping(uint256 => uint256)) public CurrentTier;
```


### EquippedCover
EquippedCover indicates the poolID of the cover that is currently equipped by the given player.

The mapping is address(player) => poolID + 1.

The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.


```solidity
mapping(address => uint256) public EquippedCover;
```


### EquippedBody
EquippedBody indicates the poolID of the body that is currently equipped by the given player.

The mapping is address(player) => poolID + 1.

The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.


```solidity
mapping(address => uint256) public EquippedBody;
```


### EquippedWheels
EquippedWheels indicates the poolID of the wheels that are currently equipped by the given player.

The mapping is address(player) => poolID + 1.

The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.


```solidity
mapping(address => uint256) public EquippedWheels;
```


### EquippedBeasts
EquippedBeasts indicates the poolID of the beasts that are currently equipped by the given player.

The mapping is address(player) => poolID + 1.

The value stored is poolID + 1 so that 0 indicates that no item is currently equipped in the slot.


```solidity
mapping(address => uint256) public EquippedBeasts;
```


## Functions
### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceID) public pure override returns (bool);
```

### constructor

Creates a JackpotJunction game contract.


```solidity
constructor(uint256 blocksToAct, uint256 costToRoll, uint256 costToReroll)
    ERC1155("https://github.com/moonstream-to/degen-trail");
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blocksToAct`|`uint256`|The number of blocks a player has to either reroll or accept the outcome of their current roll.|
|`costToRoll`|`uint256`|The cost in the finest denomination of the native token on the chain to roll.|
|`costToReroll`|`uint256`|The cost in the finest denomination of the native token on the chain to reroll.|


### receive

Allows the contract to receive the native token on its blockchain.


```solidity
receive() external payable;
```

### onERC1155Received


```solidity
function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4);
```

### onERC1155BatchReceived


```solidity
function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
    public
    virtual
    returns (bytes4);
```

### _enforceDeadline


```solidity
function _enforceDeadline(address degenerate) internal view;
```

### _enforceNotRolling


```solidity
function _enforceNotRolling(address degenerate) internal view;
```

### genera

Returns the itemType, terrainType, and tier of a given pool ID.


```solidity
function genera(uint256 poolID) public pure returns (uint256 itemType, uint256 terrainType, uint256 tier);
```

### hasBonus

Returns true if the given player currently has a bonus applied to them from their equipped items and false otherwise.


```solidity
function hasBonus(address degenerate) public view returns (bool bonus);
```

### sampleUnmodifiedOutcomeCumulativeMass

Samples from unmodified distribution over outcomes.


```solidity
function sampleUnmodifiedOutcomeCumulativeMass(uint256 entropy) public view returns (uint256);
```

### sampleImprovedOutcomesCumulativeMass

Samples from bonus distribution over outcomes.


```solidity
function sampleImprovedOutcomesCumulativeMass(uint256 entropy) public view returns (uint256);
```

### roll

Rolls or rerolls for the `msg.sender`, depending on whether or not whether `BlocksToAct` blocks
have elapsed since their last roll. If that number of blocks has elapsed, then the player is rolling
and must pay `CostToRoll`. Otherwise, the player is rerolling and must be `CostToReroll`.


```solidity
function roll() external payable;
```

### _entropy


```solidity
function _entropy(address degenerate) internal view virtual returns (uint256);
```

### currentRewards

Returns the current small, medium, and large rewards based on the game contract's native
token balance.


```solidity
function currentRewards() public view returns (uint256 small, uint256 medium, uint256 large);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`small`|`uint256`|The current small reward (in Wei)|
|`medium`|`uint256`|The current medium reward (in Wei)|
|`large`|`uint256`|The current large reward (in Wei)|


### outcome

If `outcome` is called at least one block after the player last rolled and before the players
block deadline expires, it shows the outcome of the player's last roll.


```solidity
function outcome(address degenerate, bool bonus) public view returns (uint256, uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`degenerate`|`address`|The address of the player|
|`bonus`|`bool`|This boolean signifies whether the outcome should be sampled from the unmodified or the improved outcome distribution|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|entropy The randomness that was used to determine the outcome of the player's last roll|
|`<none>`|`uint256`|_outcome The outcome of the player's last roll - this is 0, 1, 2, 3, or 4 and represents an index in either `UnmodifiedOutcomesCumulativeMass` or `ImprovedOutcomesCumulativeMass` (depending on whether a bonus was applied)|
|`<none>`|`uint256`|reward This represents a numerical parameter representing the reward that the player should receive. If the `_outcome` was `0`, this value is irrelevant and should be ignored. If the `_outcome` was `1`, signifying that the player will receive an item, this value is the ERC1155 `tokenID` of the item that will be transferred to the player if they accept the outcome, if the `_outcome` was `2`, `3`, or `4`, this value is the amount of native tokens that will be transferred to the player if they accept the outcome.|


### _award


```solidity
function _award(uint256 _outcome, uint256 value) internal;
```

### _clearRoll


```solidity
function _clearRoll() internal;
```

### accept

If a player calls this method at least one block after they last rolled and before their block deadline expires,
it accepts the outcome of their last roll and transfers the corresponding reward to their account.


```solidity
function accept() external nonReentrant returns (uint256, uint256, uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|entropy The randomness that was used to determine the outcome of the player's last roll|
|`<none>`|`uint256`|_outcome The outcome of the player's last roll - this is 0, 1, 2, 3, or 4 and represents an index in either `UnmodifiedOutcomesCumulativeMass` or `ImprovedOutcomesCumulativeMass` (depending on whether a bonus was applied)|
|`<none>`|`uint256`|reward This represents a numerical parameter representing the reward that the player should receive. If the `_outcome` was `0`, this value is irrelevant and should be ignored. If the `_outcome` was `1`, signifying that the player will receive an item, this value is the ERC1155 `tokenID` of the item that will be transferred to the player if they accept the outcome, if the `_outcome` was `2`, `3`, or `4`, this value is the amount of native tokens that will be transferred to the player if they accept the outcome.|


### equip


```solidity
function equip(uint256[] calldata poolIDs) external nonReentrant;
```

### unequip


```solidity
function unequip() external nonReentrant;
```

### craft


```solidity
function craft(uint256 poolID, uint256 numOutputs) external nonReentrant returns (uint256 newPoolID);
```

### burn


```solidity
function burn(uint256 poolID, uint256 amount) external;
```

### burnBatch


```solidity
function burnBatch(uint256[] memory poolIDs, uint256[] memory amounts) external;
```

### poolMetadata


```solidity
function poolMetadata(uint256 poolID) public pure returns (bytes memory json);
```

### uri


```solidity
function uri(uint256 poolID) public pure override returns (string memory);
```

## Events
### TierUnlocked
Fired when a new tier is unlocked for the givem itemType and terrainType. Specifies the tier and
its pool ID.


```solidity
event TierUnlocked(uint256 indexed itemType, uint256 indexed terrainType, uint256 indexed tier, uint256 poolID);
```

### Roll
Fired when a player rolls (and rerolls).


```solidity
event Roll(address indexed player);
```

### Award
Fired when a player accepts the outcome of a roll.


```solidity
event Award(address indexed player, uint256 indexed outcome, uint256 value);
```

## Errors
### DeadlineExceeded
Signifies that the player is no longer able to act because too many blocks elapsed since their
last action.


```solidity
error DeadlineExceeded();
```

### RollInProgress
Signifies that a player cannot take an action that requires them to be out of a roll because it
is too soon since they rolled. This error is raised when a player tries to equip or unequip items
while they are in the middle of a roll.


```solidity
error RollInProgress();
```

### WaitForTick
This error is raised to signify that the player needs to wait for at least one more block to elapse.


```solidity
error WaitForTick();
```

### InsufficientValue
Signifies that the player has not provided enough value to perform the action.


```solidity
error InsufficientValue();
```

### InvalidItem
Signifies that the player attempted to use an invalid item to perform a certain action.


```solidity
error InvalidItem(uint256 poolID);
```

### InsufficientItems
Signifies that the player does not have enough items in their possession to perform an action.


```solidity
error InsufficientItems(uint256 poolID);
```

