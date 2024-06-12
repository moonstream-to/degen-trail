# IDegenTrail
[Git Source](https://github.com/moonstream-to/degen-trail/blob/12818faf377f56483b501c0785ece8f05d0f77bb/src/interfaces.sol)


## Functions
### EnvironmentDistributions


```solidity
function EnvironmentDistributions(uint256, uint256) external view returns (uint8);
```

### Hex


```solidity
function Hex(uint256, uint256) external view returns (uint256);
```

### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```

### approve


```solidity
function approve(address spender, uint256 value) external returns (bool);
```

### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### board


```solidity
function board(uint256[2][] memory indices) external view returns (uint256[3][] memory);
```

### burn


```solidity
function burn(uint256 amount) external;
```

### decimals


```solidity
function decimals() external pure returns (uint8);
```

### environment


```solidity
function environment(uint256 i) external pure returns (uint256);
```

### hexp


```solidity
function hexp(uint256 i, uint256 j) external pure returns (bool);
```

### incinerate


```solidity
function incinerate() external;
```

### name


```solidity
function name() external view returns (string memory);
```

### neighborsp


```solidity
function neighborsp(uint256 i1, uint256 j1, uint256 i2, uint256 j2) external pure returns (bool);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### transfer


```solidity
function transfer(address to, uint256 value) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 value) external returns (bool);
```

## Events
### Approval

```solidity
event Approval(address owner, address spender, uint256 value);
```

### Transfer

```solidity
event Transfer(address from, address to, uint256 value);
```

## Errors
### ERC20InsufficientAllowance

```solidity
error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
```

### ERC20InsufficientBalance

```solidity
error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
```

### ERC20InvalidApprover

```solidity
error ERC20InvalidApprover(address approver);
```

### ERC20InvalidReceiver

```solidity
error ERC20InvalidReceiver(address receiver);
```

### ERC20InvalidSender

```solidity
error ERC20InvalidSender(address sender);
```

### ERC20InvalidSpender

```solidity
error ERC20InvalidSpender(address spender);
```

