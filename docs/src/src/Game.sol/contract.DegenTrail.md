# DegenTrail
[Git Source](https://github.com/moonstream-to/degen-trail/blob/54902d73c65c7678878504a329fd1306cb1d1d95/src/Game.sol)

**Inherits:**
ERC20

**Author:**
Moonstream Engineering (engineering@moonstream.to)

This is the game contract for The Degen Trail, a fully on-chain degenerate homage to The Oregon
Trail.


## State Variables
### u8mask

```solidity
uint256 private constant u8mask = 0xFF;
```


### u7mask

```solidity
uint256 private constant u7mask = 0x7F;
```


### Hex
Maps (i,j)-indices (vertical then horizontal) to the state of the corresponding hex on the game board.

State is encoded in binary. The layout of the state is: TTTE.

E: The least significant bit is 1 if the hex has been explored and 0 otherwise.

T: The 2^1, 2^2, and 2^3 bits form an integer representing the terrain type. It is an integer between 0 and 6 (inclusive). View the description of EnvironmentDescriptions to see the corresponding terrain type.


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
constructor() ERC20("Supply", "SUPPLY");
```

### decimals

The SUPPLY ERC20 token has 0 decimal places.


```solidity
function decimals() public pure override returns (uint8);
```

### burn

Burns the given amount from the SUPPLY held by msg.sender.


```solidity
function burn(uint256 amount) external;
```

### incinerate

Burns all the SUPPLY held by msg.sender.


```solidity
function incinerate() external;
```

### _explore

Internal method that explores a hex and sets its state.


```solidity
function _explore(uint256 i, uint256 j, uint256 entropy) internal;
```

### environment

Describes the environment of a hex with the given i-coordinate.


```solidity
function environment(uint256 i) public pure returns (uint256);
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

### board

Returns the current state of the board for the hexes with the given indices.

*This method is provided for convenience. Another alternative to calling this method would be to
view the Hex mapping via a multicall contract.*


```solidity
function board(uint256[2][] memory indices) external view returns (uint256[3][] memory);
```

