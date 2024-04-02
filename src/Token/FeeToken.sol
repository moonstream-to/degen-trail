// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Helpers/Validator.sol";

contract FeeToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,        
        uint256 initialSupply,
        address owner
    ) ERC20(_name, _symbol) {
        Validator.checkForZeroAddress(owner);

        _mint(owner, initialSupply);
    }

}