# DegenTrail
[Git Source](https://github.com/moonstream-to/degen-trail/blob/91d599fa04455251df8a05693dc047b6ec0fd0cd/src/Game.sol)

**Inherits:**
[Bandit](/src/Bandit.sol/contract.Bandit.md), ERC20

**Author:**
Moonstream Engineering (engineering@moonstream.to)

This is the game contract for The Degen Trail, a fully on-chain degenerate homage to The Oregon
Trail.


## State Variables
### u8mask

```solidity
uint256 private constant u8mask = 2 ^ 8 - 1;
```


### Hex
Maps (i,j)-indices (vertical then horizontal) to the state of the corresponding hex on the game board.


```solidity
mapping(uint256 => mapping(uint256 => uint256)) public Hex;
```


### EnvironmentDistributions
For each environment, lists the cumulative distribution function for terrains in that environment.

*Environments are: 0 - forest, 1 - prairie, 2 - river, 3 - arctic, 4 - marsh, 5 - badlands, 6 - hills*

*Terrain types are: 0 - plain, 1 - forest, 2 - swamp, 3 - water, 4 - mountain, 5 - desert, 6 - ice*


```solidity
uint8[7][7] public EnvironmentDistributions = [
    [0, 90, 98, 123, 128, 128, 128],
    [90, 95, 100, 120, 120, 128, 128],
    [0, 0, 8, 128, 128, 128, 128],
    [0, 8, 8, 8, 28, 28, 128],
    [5, 10, 108, 128, 128, 128, 128],
    [18, 18, 18, 18, 28, 128, 128],
    [0, 43, 43, 48, 128, 128, 128]
];
```


## Functions
### constructor


```solidity
constructor(uint256 blocksToAct, uint256 rollFee, uint256 rerollFee)
    Bandit(blocksToAct, address(this), rollFee, rerollFee)
    ERC20("Supply", "SUPPLY");
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blocksToAct`|`uint256`|Number of blocks that a player has to decide whether to accept their fate or re-roll. This parameter applies to every such decision point.|
|`rollFee`|`uint256`|Fee for first roll on any action.|
|`rerollFee`|`uint256`|Fee for re-roll on any action, assuming player doesn't want to accept their fate.|


### environment

Describes the environment of a hex with the given j-coordinate.


```solidity
function environment(uint256 j) public pure returns (uint8);
```

### hexp

Returns true if (i,j) is a valid coordinate for a hex on the game board.

*(i,j) is only a valid coordinate for a hex on the game board if i and j have the same parity and if j < 200.*

*Predicate*


```solidity
function hexp(uint256 i, uint256 j) public pure returns (bool);
```

### neighborsp

Returns true if (i1,j1) and (i2,j2) are neighbors on the game board.

*Predicate*


```solidity
function neighborsp(uint256 i1, uint256 j1, uint256 i2, uint256 j2) public pure returns (bool);
```

