# NFTBandit
[Git Source](https://github.com/moonstream-to/degen-trail/blob/86e9cb2e87f3a2ab0e67804602112ff5b0b272b0/src/Bandit.sol)

**Author:**
Moonstream Engineering (engineering@moonstream.to)

This is analogous to the PlayerBandit, except that each action is related to an ERC721 token
rather than an Ethereum account.


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

### rollForNFT


```solidity
function rollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256);
```

### _checkNFTDeadline


```solidity
function _checkNFTDeadline(address tokenAddress, uint256 tokenID) internal view;
```

### _waitForTickForNFT


```solidity
function _waitForTickForNFT(address tokenAddress, uint256 tokenID) internal view;
```

### _entropyForNFT


```solidity
function _entropyForNFT(address tokenAddress, uint256 tokenID) internal returns (bytes32);
```

### rerollForNFT


```solidity
function rerollForNFT(address tokenAddress, uint256 tokenID) public returns (uint256);
```

## Events
### NFTRoll

```solidity
event NFTRoll(address indexed tokenAddress, uint256 indexed tokenID);
```

### NFTEntropyUsed

```solidity
event NFTEntropyUsed(address indexed tokenAddress, uint256 indexed tokenID, bytes32 entropy);
```

## Errors
### NFTDeadlineExceeded

```solidity
error NFTDeadlineExceeded(address tokenAddress, uint256 tokenID);
```

### WaitForNFTTick

```solidity
error WaitForNFTTick(address tokenAddress, uint256 tokenID);
```

### NFTNotOwnedByPlayer

```solidity
error NFTNotOwnedByPlayer(address player, address tokenAddress, uint256 tokenID);
```

