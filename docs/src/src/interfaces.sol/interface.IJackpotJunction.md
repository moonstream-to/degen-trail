# IJackpotJunction
[Git Source](https://github.com/moonstream-to/degen-trail/blob/54902d73c65c7678878504a329fd1306cb1d1d95/src/interfaces.sol)


## Functions
### BlocksToAct


```solidity
function BlocksToAct() external view returns (uint256);
```

### CostToReroll


```solidity
function CostToReroll() external view returns (uint256);
```

### CostToRoll


```solidity
function CostToRoll() external view returns (uint256);
```

### CurrentTier


```solidity
function CurrentTier(uint256, uint256) external view returns (uint256);
```

### EquippedBeasts


```solidity
function EquippedBeasts(address) external view returns (uint256);
```

### EquippedBody


```solidity
function EquippedBody(address) external view returns (uint256);
```

### EquippedCover


```solidity
function EquippedCover(address) external view returns (uint256);
```

### EquippedWheels


```solidity
function EquippedWheels(address) external view returns (uint256);
```

### ImprovedOutcomesCumulativeMass


```solidity
function ImprovedOutcomesCumulativeMass(uint256) external view returns (uint256);
```

### LastRollBlock


```solidity
function LastRollBlock(address) external view returns (uint256);
```

### UnmodifiedOutcomesCumulativeMass


```solidity
function UnmodifiedOutcomesCumulativeMass(uint256) external view returns (uint256);
```

### accept


```solidity
function accept() external returns (uint256, uint256, uint256);
```

### balanceOf


```solidity
function balanceOf(address account, uint256 id) external view returns (uint256);
```

### balanceOfBatch


```solidity
function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
```

### burn


```solidity
function burn(uint256 poolID, uint256 amount) external;
```

### burnBatch


```solidity
function burnBatch(uint256[] memory poolIDs, uint256[] memory amounts) external;
```

### craft


```solidity
function craft(uint256 poolID, uint256 numOutputs) external returns (uint256 newPoolID);
```

### equip


```solidity
function equip(uint256[] memory poolIDs) external;
```

### genera


```solidity
function genera(uint256 poolID) external pure returns (uint256 itemType, uint256 terrainType, uint256 tier);
```

### hasBonus


```solidity
function hasBonus(address degenerate) external view returns (bool bonus);
```

### isApprovedForAll


```solidity
function isApprovedForAll(address account, address operator) external view returns (bool);
```

### onERC1155BatchReceived


```solidity
function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
    external
    returns (bytes4);
```

### onERC1155Received


```solidity
function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
```

### outcome


```solidity
function outcome(address degenerate, bool bonus) external view returns (uint256, uint256, uint256);
```

### roll


```solidity
function roll() external;
```

### safeBatchTransferFrom


```solidity
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
) external;
```

### safeTransferFrom


```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;
```

### sampleImprovedOutcomesCumulativeMass


```solidity
function sampleImprovedOutcomesCumulativeMass(uint256 entropy) external view returns (uint256);
```

### sampleUnmodifiedOutcomeCumulativeMass


```solidity
function sampleUnmodifiedOutcomeCumulativeMass(uint256 entropy) external view returns (uint256);
```

### setApprovalForAll


```solidity
function setApprovalForAll(address operator, bool approved) external;
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceID) external pure returns (bool);
```

### unequip


```solidity
function unequip() external;
```

### uri


```solidity
function uri(uint256) external view returns (string memory);
```

## Events
### ApprovalForAll

```solidity
event ApprovalForAll(address account, address operator, bool approved);
```

### Award

```solidity
event Award(address player, uint256 outcome, uint256 value);
```

### Roll

```solidity
event Roll(address player);
```

### TierUnlocked

```solidity
event TierUnlocked(uint256 itemType, uint256 terrainType, uint256 tier, uint256 poolID);
```

### TransferBatch

```solidity
event TransferBatch(address operator, address from, address to, uint256[] ids, uint256[] values);
```

### TransferSingle

```solidity
event TransferSingle(address operator, address from, address to, uint256 id, uint256 value);
```

### URI

```solidity
event URI(string value, uint256 id);
```

## Errors
### DeadlineExceeded

```solidity
error DeadlineExceeded();
```

### ERC1155InsufficientBalance

```solidity
error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);
```

### ERC1155InvalidApprover

```solidity
error ERC1155InvalidApprover(address approver);
```

### ERC1155InvalidArrayLength

```solidity
error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
```

### ERC1155InvalidOperator

```solidity
error ERC1155InvalidOperator(address operator);
```

### ERC1155InvalidReceiver

```solidity
error ERC1155InvalidReceiver(address receiver);
```

### ERC1155InvalidSender

```solidity
error ERC1155InvalidSender(address sender);
```

### ERC1155MissingApprovalForAll

```solidity
error ERC1155MissingApprovalForAll(address operator, address owner);
```

### InsufficientItems

```solidity
error InsufficientItems(uint256 poolID);
```

### InsufficientValue

```solidity
error InsufficientValue();
```

### InvalidItem

```solidity
error InvalidItem(uint256 poolID);
```

### ReentrancyGuardReentrantCall

```solidity
error ReentrancyGuardReentrantCall();
```

### RollInProgress

```solidity
error RollInProgress();
```

### WaitForTick

```solidity
error WaitForTick();
```

