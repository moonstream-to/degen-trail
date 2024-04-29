// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "forge-std/Test.sol";
import "../src/Bandit.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("test", "test") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract MockERC721 is ERC721 {
    constructor() ERC721("test", "test") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract MockBandit is Bandit {
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee)
        Bandit(blocksToAct, feeTokenAddress, rollFee, rerollFee)
    {}

    function resolveForPlayer() public returns (uint256) {
        return _entropyForPlayer(msg.sender);
    }

    function resolveForNFT(address tokenAddress, uint256 tokenID) public returns (uint256) {
        return _entropyForNFT(tokenAddress, tokenID);
    }
}

contract BanditTest is Test {
    MockERC20 public feeToken;
    MockBandit public bandit;
    MockERC721 public nfts;

    uint256 player1PrivateKey = 0x1;
    address player1 = vm.addr(player1PrivateKey);

    uint256 blockDeadline = 30;
    uint256 rollFee = 10;
    uint256 rerollFee = 3;

    // Bandit events
    event PlayerRoll(address indexed player);
    event NFTRoll(address indexed tokenAddress, uint256 indexed tokenID);
    event PlayerEntropyUsed(address indexed player, uint256 entropy);
    event NFTEntropyUsed(address indexed tokenAddress, uint256 indexed tokenID, uint256 entropy);

    function setUp() public {
        feeToken = new MockERC20();
        bandit = new MockBandit(blockDeadline, address(feeToken), rollFee, rerollFee);
        nfts = new MockERC721();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function testResolveForPlayerFailsOnSameBlockAsRoll() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.expectRevert(abi.encodeWithSelector(Bandit.WaitForPlayerTick.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function testResolveForPlayer() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + 1);
        uint256 expectedEntropy = uint256(blockhash(block.number - 1));
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerEntropyUsed(player1, expectedEntropy);
        uint256 entropy = bandit.resolveForPlayer();
        assertEq(entropy, expectedEntropy);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function testResolveForPlayerFailsAfterBlockDeadline() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Bandit.PlayerDeadlineExceeded.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function testResolveForNFTFailsOnSameBlockAsRoll() public {
        vm.startPrank(player1);
        uint256 tokenID = 1;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.expectRevert(abi.encodeWithSelector(Bandit.WaitForNFTTick.selector, address(nfts), tokenID));
        bandit.resolveForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function testResolveForNFT() public {
        vm.startPrank(player1);
        uint256 tokenID = 2;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), 2);
        vm.roll(block.number + 1);
        uint256 expectedEntropy = uint256(blockhash(block.number - 1));
        vm.expectEmit(true, true, false, false, address(bandit));
        emit NFTEntropyUsed(address(nfts), tokenID, expectedEntropy);
        uint256 entropy = bandit.resolveForNFT(address(nfts), tokenID);
        assertEq(entropy, expectedEntropy);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function testResolveForNFTFailsAfterBlockDeadline() public {
        vm.startPrank(player1);
        uint256 tokenID = 3;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Bandit.NFTDeadlineExceeded.selector, address(nfts), tokenID));
        bandit.resolveForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - rerollForPlayer
     */
    function testRerollForPlayer() public {
        vm.startPrank(player1);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rerollForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - rerollForPlayer
     */
    function testRerollForPlayerFailsAfterBlockDeadline() public {
        vm.startPrank(player1);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Bandit.PlayerDeadlineExceeded.selector, player1));
        bandit.rerollForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - rerollForNFT
     */
    function testRerollForNFT() public {
        vm.startPrank(player1);
        uint256 tokenID = 4;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rerollForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - rerollForNFT
     */
    function testRerollForNFTFailsAfterBlockDeadline() public {
        vm.startPrank(player1);
        uint256 tokenID = 5;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Bandit.NFTDeadlineExceeded.selector, address(nfts), tokenID));
        bandit.rerollForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }
}
