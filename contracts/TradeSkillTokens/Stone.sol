// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/Operator.sol";
import "../interfaces/ITradeskillToken.sol";

 contract Stone is ERC20, Operator, ITradeskillToken {
    constructor() ERC20("Stone", "Stone") {}

    function mintTo(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyOperator {
        _burn(from, amount);
    }
}