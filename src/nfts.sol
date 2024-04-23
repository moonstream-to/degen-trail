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
    /// @notice Stats for each NFT: tokenID => stats
    /// @dev For a token which does not exit, the stats are 0
    mapping(uint256 => DegenTrailStats) public stats;
    IDegenTrail public game;

    constructor(string memory _name, string memory _symbol, uint256 blocksToAct, address gameAddress, uint256 rollFee, uint256 rerollFee) ERC721(_name, _symbol) PlayerBandit(blocksToAct, gameAddress, rollFee, rerollFee) {
        game = IDegenTrail(gameAddress);
    }

    // Overrides needed because ERC721Enumerable itself inherits from ERC721
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

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

    /// @notice Assuming the given player has rolled or rerolled for entropy and the current block is before
    /// the block deadline, and that the roll was made more than a block ago, this function returns the
    /// stats of the NFT that the player would mint.
    /// @notice The stats are returned in the order: speed, fight, repair, recovery.
    function simulateMint(address player) public view returns (uint256, uint256, uint256, uint256) {
        _checkPlayerDeadline(player);
        _waitForTickForPlayer(player);
        uint256 entropy = uint256(blockhash(LastRollForPlayer[player]));
    }

    function _generateStats(address player, uint256 entropy) internal returns (uint256, uint256, uint256, uint256) {
    }
}
