// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @title A library for validating various conditions in smart contracts
library Validator {    
    /// @dev Error to be thrown when a zero address is provided
    error ZeroAddressNotAllowed();
    /// @dev Error to be thrown when an empty bytes32 value is provided
    error InvalidBytes32();
    /// @dev Error to be thrown when an empty bytes value is provided
    error InvalidBytes();
    /// @dev Error to be thrown when a contract does not support a required interface
    error IncompatibleNFTContract();

    /// @notice Validates that an address is not the zero address
    /// @param _address The address to validate
    function checkForZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert ZeroAddressNotAllowed();
        }
    }

    /// @notice Validates that a bytes32 value is not empty
    /// @param value The bytes32 value to validate
    function checkForZeroBytes32(bytes32 value) internal pure {
        if (value.length == 0) {
            revert InvalidBytes32();
        }
    }

    /// @notice Validates that a bytes value is not empty
    /// @param value The bytes value to validate
    function checkForZeroBytes(bytes memory value) internal pure {
        if (value.length == 0) {
            revert InvalidBytes();
        }
    }

    /// @notice Checks if a contract supports a specific interface according to ERC165
    /// @param _contractAddress The address of the contract to check
    /// @param _interfaceId The interface identifier to check for
    function checkSupportsInterface(
        address _contractAddress,
        bytes4 _interfaceId
    ) internal view {
        bool isSupported = ERC165Checker.supportsInterface(
            _contractAddress,
            _interfaceId
        );

        if (!isSupported) {
            revert IncompatibleNFTContract();
        }
    }
}