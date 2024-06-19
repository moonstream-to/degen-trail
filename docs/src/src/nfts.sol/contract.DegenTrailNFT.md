# DegenTrailNFT
[Git Source](https://github.com/moonstream-to/degen-trail/blob/40af20e32bc776b1e486a03cb53609e6918f69b1/src/nfts.sol)

**Inherits:**
ERC721, ERC721Enumerable

**Author:**
Moonstream Engineering (engineering@moonstream.to)


## State Variables
### recoveryMask
*Mask for raw recovery stat: least significant 54 bits*


```solidity
uint256 public constant recoveryMask = 2 ^ 55 - 1;
```


### repairMask
*Mask for raw repair stat: next 54 bits*


```solidity
uint256 public constant repairMask = recoveryMask << 54;
```


### fightMask
*Mask for raw fight stat: next 54 bits*


```solidity
uint256 public constant fightMask = repairMask << 54;
```


### speedMask
*Mask for raw speed stat: next 54 bits*


```solidity
uint256 public constant speedMask = fightMask << 54;
```


### kindMask
*Mask for raw kind stat: most significant 40 bits*


```solidity
uint256 public constant kindMask = speedMask << 54;
```


### stats
Stats for each NFT: tokenID => stats

*For a token which does not exit, the stats are 0*


```solidity
mapping(uint256 => DegenTrailStats) public stats;
```


### game

```solidity
IDegenTrail public game;
```


## Functions
### constructor


```solidity
constructor(string memory _name, string memory _symbol, address gameAddress) ERC721(_name, _symbol);
```

### _update

*Override needed because ERC721Enumerable itself inherits from ERC721*


```solidity
function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address);
```

### _increaseBalance

*Override needed because ERC721Enumerable itself inherits from ERC721*


```solidity
function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable);
```

### supportsInterface

*Override needed because ERC721Enumerable itself inherits from ERC721*


```solidity
function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool);
```

### _metadataName


```solidity
function _metadataName(uint256 tokenID) internal view virtual returns (string memory);
```

### _metadataKind


```solidity
function _metadataKind(uint256 kind) internal view virtual returns (string memory);
```

### metadataJSONBytes


```solidity
function metadataJSONBytes(uint256 tokenID) public view returns (bytes memory);
```

### metadataJSON


```solidity
function metadataJSON(uint256 tokenID) external view returns (string memory);
```

### tokenURI


```solidity
function tokenURI(uint256 tokenID) public view override returns (string memory);
```

