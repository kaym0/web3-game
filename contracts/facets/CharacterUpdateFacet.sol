// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { Character, CharacterSkill, CharacterSeed, ICharacters } from "../interfaces/ICharacters.sol";
import { CharacterStorage } from "../libraries/CharacterStorage.sol";

/**
 *
 *  @title Character Update Facet
 *  
 *  @author kaymo.eth
 *
 *  @dev Designed to update character values; This is specifically for non-level related upgrades to characters which are gained through alternative methods.
 *
 */
contract CharacterUpdateFacet {

    CharacterStorage _state;

    error NotOperator();

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Not owner");
        _;
    }

    modifier onlyOperator {
        if (LibDiamond.diamondStorage().operators[msg.sender] == false) revert NotOperator();
        _;
    }

    /**
     *
     *  @dev Updates character stamina
     *
     */
    function updateCharacterStamina(uint256 cid, uint256 staminaAmount) external onlyOperator {
        Character storage character = _state.characters[cid];
        character.stamina = character.stamina + staminaAmount;
    }


    /**
     *
     *  @dev Updates character speed boost.
     *
     */
    function updateCharacterSpeedBoost(uint256 cid, uint256 speedBoost) external onlyOwner {
        Character storage character = _state.characters[cid];

        character.multipliers.speed = character.multipliers.speed + speedBoost;
    }


    /**
     *
     *  @dev Updates character exp boost.
     *
     */
    function updateCharacterExpBoost(uint256 cid, uint256 expBoost) external onlyOwner {
        Character storage character = _state.characters[cid];

        character.multipliers.exp = character.multipliers.exp + expBoost;
    }


    /**
     *
     *  @dev Updates character gem boost.
     *
     */
    function updateCharacterGemBoost(uint256 cid, uint256 gemBoost) external onlyOwner {
        Character storage character = _state.characters[cid];

        character.multipliers.gems = character.multipliers.gems + gemBoost;
    }


    /**
     *
     *  @dev Updates character drop boost.
     *
     */
    function updateCharacterDropBoost(uint256 cid, uint256 dropBoost) external onlyOwner {
        Character storage character = _state.characters[cid];

        character.multipliers.drops = character.multipliers.drops + dropBoost;
    }

}