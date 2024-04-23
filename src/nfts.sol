// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC721Enumerable} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {PlayerBandit} from "./Bandit.sol";
import {DegenTrailStats} from "./data.sol";
import {IDegenTrail} from "./interfaces.sol";

/// @title Degen Trail base NFT contract
/// @author Moonstream Engineering (engineering@moonstream.to)
contract DegenTrailNFT is ERC721, ERC721Enumerable, PlayerBandit {
    /// @dev Mask for raw recovery stat: least significant 54 bits
    uint256 public constant recoveryMask = 2^55 - 1;
    /// @dev Mask for raw repair stat: next 54 bits
    uint256 public constant repairMask = recoveryMask << 54;
    /// @dev Mask for raw fight stat: next 54 bits
    uint256 public constant fightMask = repairMask << 54;
    /// @dev Mask for raw speed stat: next 54 bits
    uint256 public constant speedMask = fightMask << 54;
    /// @dev Mask for raw kind stat: most significant 40 bits
    uint256 public constant kindMask = speedMask << 54;

    /// @notice Stats for each NFT: tokenID => stats
    /// @dev For a token which does not exit, the stats are 0
    mapping(uint256 => DegenTrailStats) public stats;
    IDegenTrail public game;

    constructor(string memory _name, string memory _symbol, uint256 blocksToAct, address gameAddress, uint256 rollFee, uint256 rerollFee) ERC721(_name, _symbol) PlayerBandit(blocksToAct, gameAddress, rollFee, rerollFee) {
        game = IDegenTrail(gameAddress);
    }

    /// @dev Override needed because ERC721Enumerable itself inherits from ERC721
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /// @dev Override needed because ERC721Enumerable itself inherits from ERC721
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    /// @dev Override needed because ERC721Enumerable itself inherits from ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Burns all SUPPLY held by this contract.
    function _postRoll() internal override {
        game.incinerate();
    }

    /// @dev Subclasses should override this to implement their desired post-processing to raw stat generation.
    /// @dev For example, a subclass might want to restruct to fewer than 2^40 - 1 kinds, or might want to limit the speed, etc.
    function _prepareStats(uint256 kindRaw, uint256 speedRaw, uint256 fightRaw, uint256 repairRaw, uint256 recoveryRaw) internal virtual pure returns (uint256 kind, uint256 speed, uint256 fight, uint256 repair, uint256 recovery) {
        kind = kindRaw;
        speed = speedRaw;
        fight = fightRaw;
        repair = repairRaw;
        recovery = recoveryRaw;
    }

    /// @dev Stats are generated from the hash of the concatenation of the player's entropy and address. The resulting 256-bit integer
    /// is then split into:
    /// @dev |- kind: 40 bits -|- speed: 54 bits -|- fight: 54 bits -|- repair: 54 bits -|- recovery: 54 bits -|
    function generateStats(address player, bytes32 entropy) public pure returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 rng = uint256(keccak256(abi.encode(entropy, player)));
        return ((rng & kindMask) >> 216, (rng & speedMask) >> 162, (rng & fightMask) >> 108, (rng & recoveryMask) >> 54, rng & repairMask);
    }

    /// @notice Assuming the given player has rolled or rerolled for entropy and the current block is before
    /// the block deadline, and that the roll was made more than a block ago, this function returns the
    /// stats of the NFT that the player would mint.
    /// @notice The stats are returned in the order: kind, speed, fight, repair, recovery.
    function simulateMint(address player) public view returns (uint256, uint256, uint256, uint256, uint256) {
        _checkPlayerDeadline(player);
        _waitForTickForPlayer(player);
        bytes32 entropy = blockhash(LastRollForPlayer[player]);
        (uint256 kindRaw, uint256 speedRaw, uint256 fightRaw, uint256 repairRaw, uint256 recoveryRaw) = generateStats(player, entropy);
        return _prepareStats(kindRaw, speedRaw, fightRaw, repairRaw, recoveryRaw);
    }

    /// @notice Mints an NFT for the caller, assuming they have rolled for NFT stats and their roll has not expired.
    function mint() external returns (uint256 kind, uint256 speed, uint256 fight, uint256 repair, uint256 recovery) {
        bytes32 entropy = _entropyForPlayer(msg.sender);
        uint256 tokenID = totalSupply() + 1;
        _mint(msg.sender, tokenID);
        (kind , speed, fight, repair, recovery) = generateStats(msg.sender, entropy);
        (kind , speed, fight, repair, recovery) = _prepareStats(kind, speed, fight, repair, recovery);
        stats[tokenID] = DegenTrailStats(kind, speed, fight, repair, recovery);
    }
}
