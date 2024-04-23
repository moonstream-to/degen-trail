# Bandit
[Git Source](https://github.com/moonstream-to/degen-trail/blob/3d1ff82bf5259e5be0b7f66e874abdb08785d375/src/Bandit.sol)

**Author:**
Moonstream Engineering (engineering@moonstream.to)

A Bandit implements a fully on-chain single-player fog-of-war mechanic that produces RNG via two
player-submitted transactions. First, a player submits a transaction expressing their intent to
generate RNG. Second, the player submits a transaction that uses RNG derived from the block hash
of their first transaction.

The player has a limited number of blocks to submit the second transaction. If they fail to submit
it in time, the entropy is wasted.

The player may also elect to re-roll RNG by submitting a new transaction before the block deadline
in which they pay a fee to re-roll. If they elect to do this, the block hash of the block in which
the transaction representing their intent to re-roll is used as the new source of entropy. The block
deadline is then calculated from this transaction block.


## State Variables
### BlocksToAct

```solidity
uint256 public BlocksToAct;
```


### FeeToken

```solidity
IERC20 public FeeToken;
```


### RollFee

```solidity
uint256 public RollFee;
```


### RerollFee

```solidity
uint256 public RerollFee;
```


### LastRollForPlayer

```solidity
mapping(address => uint256) public LastRollForPlayer;
```


### LastRollForNFT

```solidity
mapping(address => mapping(uint256 => uint256)) public LastRollForNFT;
```


## Functions
### _preRollForNFT


```solidity
function _preRollForNFT(address tokenAddress, uint256 tokenID) internal virtual;
```

### _postRoll


```solidity
function _postRoll() internal virtual;
```

### constructor


```solidity
constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blocksToAct`|`uint256`|Number of blocks that a player has to decide whether to accept their fate or re-roll. This parameter applies to every such decision point.|
|`feeTokenAddress`|`address`|Address of ERC20 token which represents fees.|
|`rollFee`|`uint256`|Fee for first roll on any action.|
|`rerollFee`|`uint256`|Fee for re-roll on any action, assuming player doesn't want to accept their fate.|


### _checkNFTOwnership


```solidity
function _checkNFTOwnership(address player, address tokenAddress, uint256 tokenID) internal view;
```

### rollForPlayer


```solidity
function rollForPlayer() public returns (uint256);
```

### rollForNFT


```solidity
function rollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256);
```

### _checkPlayerDeadline


```solidity
function _checkPlayerDeadline(address player) internal view;
```

### _checkNFTDeadline


```solidity
function _checkNFTDeadline(address tokenAddress, uint256 tokenID) internal view;
```

### _waitForTickForPlayer


```solidity
function _waitForTickForPlayer(address player) internal view;
```

### _waitForTickForNFT


```solidity
function _waitForTickForNFT(address tokenAddress, uint256 tokenID) internal view;
```

### _entropyForPlayer


```solidity
function _entropyForPlayer(address player) internal returns (uint256);
```

### _entropyForNFT


```solidity
function _entropyForNFT(address tokenAddress, uint256 tokenID) internal returns (uint256);
```

### rerollForPlayer


```solidity
function rerollForPlayer() public returns (uint256);
```

### rerollForNFT


```solidity
function rerollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256);
```

## Events
### PlayerRoll

```solidity
event PlayerRoll(address indexed player);
```

### NFTRoll

```solidity
event NFTRoll(address indexed tokenAddress, uint256 indexed tokenID);
```

### PlayerEntropyUsed

```solidity
event PlayerEntropyUsed(address indexed player, uint256 entropy);
```

### NFTEntropyUsed

```solidity
event NFTEntropyUsed(address indexed tokenAddress, uint256 indexed tokenID, uint256 entropy);
```

## Errors
### PlayerDeadlineExceeded

```solidity
error PlayerDeadlineExceeded(address player);
```

### NFTDeadlineExceeded

```solidity
error NFTDeadlineExceeded(address tokenAddress, uint256 tokenID);
```

### WaitForPlayerTick

```solidity
error WaitForPlayerTick(address player);
```

### WaitForNFTTick

```solidity
error WaitForNFTTick(address tokenAddress, uint256 tokenID);
```

### NFTNotOwnedByPlayer

```solidity
error NFTNotOwnedByPlayer(address player, address tokenAddress, uint256 tokenID);
```

