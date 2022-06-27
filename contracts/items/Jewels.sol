// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../token/ERC721/ERC721A.sol";
import "../token/ERC721/extensions/ERC721AQueryable.sol";
import "../interfaces/IEquipment.sol";
import { JewelType, Jewel } from "../interfaces/IJewels.sol";
import "../access/Operator.sol";

contract Jewels is ERC721AQueryable, Operator {

    uint256 public index;

    mapping (uint256 => Jewel) jewels;

    event JewelCrafted(uint256 indexed id, JewelType indexed jewelType, address indexed owner);
    event JewelDestroyed(uint256 indexed id);
    
    constructor() ERC721A("Jewel","Jewels") {

    }

    function createJewel(address to) external onlyOperator {
        _mint(to, 1);
        jewels[index] = Jewel(JewelType.SWIFTNESS, false);

        emit JewelCrafted(index, JewelType.SWIFTNESS, to);

        index = index + 1;
    }

    function destroyJewel(uint256 id) external {
        _burn(id);

        emit JewelDestroyed(id);
    }
}