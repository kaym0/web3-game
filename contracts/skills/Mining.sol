// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/Operator.sol";

contract Mining is ERC20, Operator {

    mapping (address => Miner) miners;

    struct Miner {
        uint256 lvl;

    }

    constructor() ERC20("Coin","Coin") {}
    
    function beginMining() external {

    }

    function mintTo (address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public onlyOperator {
        _burn(from, amount);
    }
}