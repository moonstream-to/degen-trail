// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "forge-std/Test.sol";
import {PlayerBandit, NFTBandit} from "../src/Bandit.sol";

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

contract MockPlayerBandit is PlayerBandit {
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee)
        PlayerBandit(blocksToAct, feeTokenAddress, rollFee, rerollFee)
    {}

    function resolveForPlayer() public returns (bytes32) {
        return _entropyForPlayer(msg.sender);
    }

}

contract MockNFTBandit is NFTBandit {
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee)
        NFTBandit(blocksToAct, feeTokenAddress, rollFee, rerollFee)
    {}

    function resolveForNFT(address tokenAddress, uint256 tokenID) public returns (bytes32) {
        return _entropyForNFT(tokenAddress, tokenID);
    }
}


contract PlayerBanditTest is Test {
    MockERC20 public feeToken;
    MockPlayerBandit public bandit;

    uint256 player1PrivateKey = 0x1;
    address player1 = vm.addr(player1PrivateKey);

    uint256 blockDeadline = 30;
    uint256 rollFee = 10;
    uint256 rerollFee = 3;

    // Bandit events
    event PlayerRoll(address indexed player);
    event PlayerEntropyUsed(address indexed player, bytes32 entropy);

    function setUp() public {
        feeToken = new MockERC20();
        bandit = new MockPlayerBandit(blockDeadline, address(feeToken), rollFee, rerollFee);
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function test_resolve_for_player_fails_on_same_block_as_roll() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.expectRevert(abi.encodeWithSelector(PlayerBandit.WaitForPlayerTick.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function test_resolve_for_player() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + 1);
        bytes32 expectedEntropy = blockhash(block.number - 1);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerEntropyUsed(player1, expectedEntropy);
        bytes32 entropy = bandit.resolveForPlayer();
        assertEq(entropy, expectedEntropy);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - _entropyForPlayer
     */
    function test_resolve_for_player_fails_after_block_deadline() public {
        vm.startPrank(player1);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(PlayerBandit.PlayerDeadlineExceeded.selector, player1));
        bandit.resolveForPlayer();
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForPlayer
     * - rerollForPlayer
     */
    function test_reroll_for_player() public {
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
    function test_reroll_for_player_fails_after_block_deadline() public {
        vm.startPrank(player1);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit PlayerRoll(player1);
        bandit.rollForPlayer();
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(PlayerBandit.PlayerDeadlineExceeded.selector, player1));
        bandit.rerollForPlayer();
        vm.stopPrank();
    }
}

contract NFTBanditTest is Test {
    MockERC20 public feeToken;
    MockNFTBandit public bandit;
    MockERC721 public nfts;

    uint256 player1PrivateKey = 0x1;
    address player1 = vm.addr(player1PrivateKey);

    uint256 blockDeadline = 30;
    uint256 rollFee = 10;
    uint256 rerollFee = 3;

    // Bandit events
    event NFTRoll(address indexed tokenAddress, uint256 indexed tokenID);
    event NFTEntropyUsed(address indexed tokenAddress, uint256 indexed tokenID, bytes32 entropy);

    function setUp() public {
        feeToken = new MockERC20();
        bandit = new MockNFTBandit(blockDeadline, address(feeToken), rollFee, rerollFee);
        nfts = new MockERC721();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function test_resolve_for_nft_fails_on_same_block_as_roll() public {
        vm.startPrank(player1);
        uint256 tokenID = 1;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.expectRevert(abi.encodeWithSelector(NFTBandit.WaitForNFTTick.selector, address(nfts), tokenID));
        bandit.resolveForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function test_resolve_for_nft() public {
        vm.startPrank(player1);
        uint256 tokenID = 2;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), 2);
        vm.roll(block.number + 1);
        bytes32 expectedEntropy = blockhash(block.number - 1);
        vm.expectEmit(true, true, false, false, address(bandit));
        emit NFTEntropyUsed(address(nfts), tokenID, expectedEntropy);
        bytes32 entropy = bandit.resolveForNFT(address(nfts), tokenID);
        assertEq(entropy, expectedEntropy);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - _entropyForNFT
     */
    function test_resolve_for_nft_fails_after_block_deadline() public {
        vm.startPrank(player1);
        uint256 tokenID = 3;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, 10);
        feeToken.approve(address(bandit), 10);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(NFTBandit.NFTDeadlineExceeded.selector, address(nfts), tokenID));
        bandit.resolveForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }

    /**
     * Tests:
     * - rollForNFT
     * - rerollForNFT
     */
    function test_reroll_for_nft() public {
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
    function test_reroll_for_nft_fails_after_block_deadline() public {
        vm.startPrank(player1);
        uint256 tokenID = 5;
        nfts.mint(player1, tokenID);
        feeToken.mint(player1, rollFee + rerollFee);
        feeToken.approve(address(bandit), rollFee + rerollFee);
        vm.expectEmit(true, true, true, false, address(bandit));
        emit NFTRoll(address(nfts), tokenID);
        bandit.rollForNFT(address(nfts), tokenID);
        vm.roll(block.number + blockDeadline + 1);
        vm.expectRevert(abi.encodeWithSelector(NFTBandit.NFTDeadlineExceeded.selector, address(nfts), tokenID));
        bandit.resolveForNFT(address(nfts), tokenID);
        vm.stopPrank();
    }
}
