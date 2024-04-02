// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "forge-std/Test.sol";
import "../src/Bandit.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock ERC20", "MOCK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract MockBandit is Bandit {
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee) Bandit(blocksToAct, feeTokenAddress, rollFee, rerollFee) {}

    function resolveForPlayer() public view returns (uint256) {
        return _entropyForPlayer(msg.sender);
    }

    function resolveForNFT(address tokenAddress, uint256 tokenID) public view returns (uint256) {
        return _entropyForNFT(tokenAddress, tokenID);
    }
}

contract BanditTest is Test {
    MockERC20 public feeToken;
    MockBandit public bandit;

    uint256 player1PrivateKey = 0x1;
    address player1 = vm.addr(player1PrivateKey);

    uint256 blockDeadline = 30;
    uint256 rollFee = 10;
    uint256 rerollFee = 3;

    function setUp() public {
        feeToken = new MockERC20();
        bandit = new MockBandit(blockDeadline, address(feeToken), rollFee, rerollFee);
    }

    function testResolveForPlayerFailsOnSameBlockAsRoll() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        bandit.rollForPlayer();
        vm.expectRevert(abi.encodeWithSelector(Bandit.WaitForPlayerTick.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }

    function testResolveForPlayer() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        bandit.rollForPlayer();
        vm.roll(block.number + 1);
        uint256 entropy = bandit.resolveForPlayer();
        uint256 expectedEntropy = uint256(blockhash(block.number - 1));
        assertEq(entropy, expectedEntropy);
        vm.stopPrank();
    }

    function testResolvePlayerFailsAfterBlockDeadline() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        bandit.rollForPlayer();
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Bandit.PlayerDeadlineExceeded.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }
}
