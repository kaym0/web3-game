// SPDX-License-Identifer: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IGems.sol";
import "./access/Operator.sol";

/// Create soulbound version of this contract which is non-transferrable except in game 
/// This will limit the abuse of the daily mint functionality.
contract Lunarium is ERC20, Operator {

    IGems public gems;
    uint256 public basePriceEth = 1 ether;
    uint256 public basePriceGems = 1000 ether;

    mapping (address => uint256) lastDailyMintEth;
    mapping (address => uint256) lastDailyMintGems;

    constructor(address _gems) ERC20("Lunarium", "LUNAR") {
        gems = IGems(_gems);
    }

    error InsufficientPayment();

    function _getConvertedCostEth(uint256 amount) private view returns (uint256) {
        return ((amount * (amount + 1)) / 2) * basePriceEth;
    }

    function _getConvertedCostGems(uint256 amount) private view returns (uint256) {
        return ((amount * (amount + 1)) / 2) * basePriceGems;
    }
    
    /**
     *
     *  @dev Mints Lunarium in exchange for Eth.
     *
     *  @param amount The amount of Lunarium to mint.
     *
     */
    function dailyMintWithEth(uint256 amount) external payable {
        if (msg.value != _getConvertedCostEth(amount)) revert InsufficientPayment();

        lastDailyMintEth[msg.sender] = block.timestamp;

        _mint(msg.sender, amount);
    }

    /**
     *
     *  @dev Mints Lunarium in exchange for gems. Gems are burned before Lunarium is minted. 
     *
     *  @param amount - The amount of Lunarium to mint.
     *
     */
    function dailyMintWithGems(uint256 amount) external {

        gems.burnFrom(msg.sender, _getConvertedCostGems(amount));

        lastDailyMintGems[msg.sender] = block.timestamp; 

        _mint(msg.sender, amount);

    }

    function mintTo(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyOperator {
        _burn(from, amount);
    }
}