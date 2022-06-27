// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/Operator.sol";

contract Gems is ERC20, Operator {

    uint256 pricePerToken = 0.000025 ether;

    constructor() ERC20("Gem Coin","Gem Coin") {}

    event PriceChanged(uint256 indexed newPrice);

    function updateTokenPrice(uint256 newPrice) external onlyOperator {
        require(newPrice != 0, "Zero");

        pricePerToken = newPrice;

        emit PriceChanged(newPrice);
    } 

    function buyTokens() external payable {
        require(msg.value != 0, "Zero");

        _mint(msg.sender, msg.value / pricePerToken);
    }


    function mintTo (address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public onlyOperator {
        _burn(from, amount);
    }
}