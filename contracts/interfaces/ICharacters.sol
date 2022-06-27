// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Equip } from "./IEquipment.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
/**
 *
 *  @dev Character seeds are used to determine a the potential of a character. Seeds which are larger numbers
 *  indicate that a characer will gain more stats over time than a character which has lesser seeds.
 *
 */
struct CharacterSeed {
    uint hp;
    uint str;
    uint def;
    uint agi;
    uint dex;
}

/**
 *
 *  @dev Basic format of tradeskill stats.
 *  Each trade skill has an individual level and experience pool.
 *
 */
struct CharacterSkill {
    uint256 level;
    uint256 exp;
}


struct CharacterMultipliers {
    uint256 speed;
    uint256 exp;
    uint256 gems;
    uint256 drops;
}

/**
 *
 *  @dev Character struct, this of character stats, including their name.
 *
 *  hp              -       represents the total health points of a character.
 *  str             -       shorthand for strength. 
 *  dex             -       shorthand for dexterity.
 *  agi             -       shorthand for agility.
 *  def             -       shorthand for def.
 *  exp             -       shorthand for experience points.
 *  id              -       the tokenID
 *  stamina         -       The time a character is capable of battling before needing to recover.
 *
 */
struct Character {
    address owner;
    string name;
    uint256 id;
    uint256 level;
    uint256 exp;
    uint256 stamina;
    uint256 hp;
    uint256 str;
    uint256 def;
    uint256 dex;
    uint256 agi;
    CharacterSkill mining;
    CharacterSkill woodcutting;
    CharacterSkill stonecutting;
    CharacterSkill fishing;
    CharacterMultipliers multipliers;
}

interface ICharacters {
    event CharacterCreated(address indexed owner, uint256 indexed id);
    event CharacterBurned(address indexed owner, uint256 indexed id);

    error NotOperator();

    error InsufficientAmount();
    error NotOwner();
    error AlreadyEquipped();
    error NotOwnerOfEquipment();

    function price() external view returns (uint256);
    function index() external view returns (uint256);
    function gainExperience(uint256 id, uint256 amount) external;
    function gainTradeExperience(uint256 cid, uint256 skillId, uint256 amount) external;
    function getCharacter(uint256 id) external view returns (Character memory);
    function burnCharacter(uint256 id) external;
    function refreshStamina(uint256 characterId) external;
}
