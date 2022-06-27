// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../access/Operator.sol";
import "../interfaces/ITradeskillToken.sol";

 contract Ore is IERC20, ERC20, Operator, ITradeskillToken {
    constructor() ERC20("Ore", "Ore") {
        _mint(msg.sender, 1e18);
    }

    function mintTo(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyOperator {
        _burn(from, amount);
    }
}