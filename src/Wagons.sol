// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC721Enumerable} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {PlayerBandit} from "./Bandit.sol";

/// @title The Degen Trail Wagons contract
/// @author Moonstream Engineering (engineering@moonstream.to)
/// @notice Implements the wagon NFTs for The Degen Trail
contract DegenTrailWagons is ERC721, ERC721Enumerable, PlayerBandit {
    constructor(uint256 blocksToAct, address feeTokenAddress, uint256 rollFee, uint256 rerollFee) ERC721("Degen Trail Wagons", "WAGON") PlayerBandit(blocksToAct, feeTokenAddress, rollFee, rerollFee) {}

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
}
