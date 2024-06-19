// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC721Enumerable} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {DegenTrailStats} from "./data.sol";
import {IDegenTrail} from "./interfaces.sol";

/// @title Degen Trail base NFT contract
/// @author Moonstream Engineering (engineering@moonstream.to)
contract DegenTrailNFT is ERC721, ERC721Enumerable {
    /// @dev Mask for raw recovery stat: least significant 54 bits
    uint256 public constant recoveryMask = 2 ^ 55 - 1;
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

    constructor(
        string memory _name,
        string memory _symbol,
        address gameAddress
    ) ERC721(_name, _symbol) {
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
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    /// @dev Override needed because ERC721Enumerable itself inherits from ERC721
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _metadataName(uint256 tokenID)
        internal
        view
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(tokenID));
    }

    function _metadataKind(uint256 kind) internal view virtual returns (string memory) {
        return string(abi.encodePacked(kind));
    }

    function metadataJSONBytes(uint256 tokenID) public view returns (bytes memory) {
        DegenTrailStats memory stat = stats[tokenID];
        return abi.encodePacked(
            '{"name": "',
            _metadataName(tokenID),
            '","kind":',
            _metadataKind(stat.kind),
            ',"speed":',
            stat.speed,
            ',"fight":',
            stat.fight,
            ',"repair":',
            stat.repair,
            ',"recovery":',
            stat.recovery,
            "}"
        );
    }

    function metadataJSON(uint256 tokenID) external view returns (string memory) {
        return string(metadataJSONBytes(tokenID));
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return string(abi.encodePacked("data:application/json;", metadataJSONBytes(tokenID)));
    }
}
