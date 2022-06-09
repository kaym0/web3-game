// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/Operator.sol";

contract Crafting is ERC20, Operator {
    constructor() ERC20("Coin","Coin") {}

    error CannotMintTo();

    function mintTo (address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public onlyOperator {
        _burn(from, amount);
    }
}