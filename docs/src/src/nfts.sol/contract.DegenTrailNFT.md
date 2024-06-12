# DegenTrailNFT
[Git Source](https://github.com/moonstream-to/degen-trail/blob/12818faf377f56483b501c0785ece8f05d0f77bb/src/nfts.sol)

**Inherits:**
ERC721, ERC721Enumerable, [PlayerBandit](/src/Bandit.sol/contract.PlayerBandit.md)

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
constructor(
    string memory _name,
    string memory _symbol,
    uint256 blocksToAct,
    address gameAddress,
    uint256 rollFee,
    uint256 rerollFee
) ERC721(_name, _symbol) PlayerBandit(blocksToAct, gameAddress, rollFee, rerollFee);
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

### _postRoll

Burns all SUPPLY held by this contract.


```solidity
function _postRoll() internal override;
```

### _prepareStats

*Subclasses should override this to implement their desired post-processing to raw stat generation.*

*For example, a subclass might want to restruct to fewer than 2^40 - 1 kinds, or might want to limit the speed, etc.*


```solidity
function _prepareStats(uint256 kindRaw, uint256 speedRaw, uint256 fightRaw, uint256 repairRaw, uint256 recoveryRaw)
    internal
    pure
    virtual
    returns (uint256 kind, uint256 speed, uint256 fight, uint256 repair, uint256 recovery);
```

### generateStats

*Stats are generated from the hash of the concatenation of the player's entropy and address. The resulting 256-bit integer
is then split into:*

*|- kind: 40 bits -|- speed: 54 bits -|- fight: 54 bits -|- repair: 54 bits -|- recovery: 54 bits -|*


```solidity
function generateStats(address player, bytes32 entropy)
    public
    pure
    returns (uint256, uint256, uint256, uint256, uint256);
```

### simulateMint

Assuming the given player has rolled or rerolled for entropy and the current block is before
the block deadline, and that the roll was made more than a block ago, this function returns the
stats of the NFT that the player would mint.

The stats are returned in the order: kind, speed, fight, repair, recovery.


```solidity
function simulateMint(address player) public view returns (uint256, uint256, uint256, uint256, uint256);
```

### mint

Mints an NFT for the caller, assuming they have rolled for NFT stats and their roll has not expired.


```solidity
function mint() external returns (uint256 kind, uint256 speed, uint256 fight, uint256 repair, uint256 recovery);
```

### _metadataName


```solidity
function _metadataName(uint256 tokenID, DegenTrailStats memory stat) internal view virtual returns (string memory);
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

