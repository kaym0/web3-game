// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { CharacterStorage } from "../libraries/CharacterStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibAppStorage } from "../libraries/LibAppStorage.sol";
import { ERC721A } from "./token/ERC721/ERC721A.sol";
import { ERC721AQueryable } from "./token/ERC721/extensions/ERC721AQueryable.sol";
import { Character, CharacterSeed, ICharacters } from "../interfaces/ICharacters.sol";
import "../interfaces/IEquipment.sol";
import "../utils/RandomUtil.sol";

/**
 *  @title Character Token Contract
 *  @author kaymo.eth
 */
contract CharacterFacet is ERC721AQueryable {

    event CharacterCreated(address indexed owner, uint256 indexed id);
    event CharacterBurned(address indexed owner, uint256 indexed id);

    error Initialized();
    error InsufficientAmount();
    error NotOwner();
    error AlreadyEquipped();
    error NotOwnerOfEquipment();


    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Not owner");
        _;
    }


    function initialize(address _equipment) public onlyOwner {
          if (state.initialized) revert Initialized();
        state.initialized = true;
        state.equipment = IEquipment(_equipment);
    }

    /**
     * 
     *  @dev Equips an item to a given character. This removes the previous equipment and replaces it with new equipment.
     *
     *  Requirements:
     *  - Caller must own the equipment.
     *  - The equipment must not be equipped already.
     *
     *  @param characterId - The character to equip
     *
     *  @param equipmentId - The equipment to apply.
     *
     */
    function equipItem(uint256 characterId, uint256 equipmentId) public {
        Character storage character = state.characters[characterId];

        if (state.equipment.ownerOf(equipmentId) != msg.sender) revert NotOwnerOfEquipment();

        Equip memory equip = state.equipment.getEquipment(equipmentId);

        if (equip.equipped == true) revert AlreadyEquipped();

        Equip memory currentEquipment = state.characterEquipment[characterId][equip.slot];

        character.hp = character.hp + equip.hp - currentEquipment.hp;
        character.str = character.str  + equip.str - currentEquipment.str;
        character.def = character.def + equip.def - currentEquipment.def;
        character.agi = character.agi + equip.agi - currentEquipment.agi;
        character.dex = character.dex + equip.dex - currentEquipment.dex;

        // Set equipment statuses.
        state.equipment.setEquipped(equipmentId, true);
        state.equipment.setEquipped(currentEquipment.id, false);
    }

    /**
     *
     *  @dev getCharacterEquipment
     *  
     *  @param id - The characterID to query
     *
     *  @return equips - An array containing the characters equipment. In order: [Weapon, Helmet, Body Armor, Gloves, Boots]
     *
     */
    function getCharacterEquipment(uint256 id) public view returns (Equip[] memory equips) {
        for (uint i; i < 5; i++) {
            equips[i] = (state.characterEquipment[id][i]);
        }
    }

    /**
     *
     *  @dev Primary function for giving characters experience points. This is called by external contracts when tasks are completed or enemies and defeated.
     *
     *  @param id - The characterID
     *
     *  @param amount - Amount of experience to assign
     *
     */
    function gainExperience(uint256 id, uint32 amount) public onlyOwner() {
        Character storage character = state.characters[id];

        character.exp = character.exp + amount;

        if (character.exp > toNextLevel(character.level)) {
            _gainLevel(character);
        }
    }

    /**
     * 
     *  @dev Calculates the amount of experience required to get to the next level from a given level.
     *
     *  @param level - The current level of the character. For example, if we supply 5 as the argument, it will give the total experience 
     *  to get from level 5 to level 6.
     *
     *  @return experienceToNextLevel
     *
     */
    function toNextLevel(uint32 level) public pure returns (uint32) {
        return ((4 * level ** 2) / 5) + 50;
    }

    /**
     *
     *  @dev Handles incrementing a characters level. This removes the experience cost from the characters exp pool and then increments 
     *  their level and stats accordingly.
     *
     *  @param character - The character object to update.
     *
     */
    function _gainLevel(Character storage character) private {
        character.exp = character.exp - toNextLevel(character.level);

        character.level = character.level + 1;
        character.hp = (character.level**3) / (character.level * 3) + 10 + (uint32(character.seeds.hp) * character.level / 255);
        character.str = (character.level**3) / (character.level * 15) + 2 + (uint32(character.seeds.str) * character.level /  255);
        character.dex = (character.level**3) / (character.level * 15) + 2 + (uint32(character.seeds.dex) * character.level /  255);
        character.agi = (character.level**3) / (character.level * 15) + 2 + (uint32(character.seeds.agi) * character.level /  255);
        character.def = (character.level**3) / (character.level * 15) + 2 + (uint32(character.seeds.def) * character.level /  255);
    }

    /**
     *
     *  @dev Collects and returns all characters which belong to a given address.
     *
     *  @param owner - The account to query.
     *
     *  @return c - An array of Character objects
     *
     */
    function getCharactersOfOwner(address owner) public view returns (Character[] memory) {
        uint256[] memory tokens = tokensOfOwner(owner);
        Character[] memory chars = new Character[](tokens.length);

        for (uint i; i < tokens.length; i++) {
            chars[i] = (state.characters[tokens[i]]);
        }

        return chars;
    }

    /**
     *
     *  @dev Queries all characters of an owner and all equipment of those characters. Two arrays are returned and run parallel to each other.
     *
     *  @param owner - The owner to query
     *
     *  @return chars - An array of characters
     *
     *  @return equips - An array of equipments which is parallel 
     *
     *
     */
    function getCharactersAndEquipOfOwner(address owner) public view returns (Character[] memory chars, Equip[] memory equips) {
         uint256[] memory tokens = tokensOfOwner(owner);

        for (uint i; i < tokens.length; i++) {
            chars[i] = (state.characters[tokens[i]]);
            
            for (uint j = 0; j < 5; j++) {
                equips[j] = state.characterEquipment[i][j];
            }
        }

    }

    /**
     *
     *  @dev Gets a character using characterID.
     *
     *  @param id - The id of the character to query
     *
     *  @return character - A character object including all stats of a character.
     *
     */
    function getCharacter(uint256 id) public view returns (Character memory) {
        return state.characters[id];
    }

    /**
     *
     *  @dev Mints a new a character for a price. Each character is generated using a seed created from dividing the previous blockhash by their address converted to uint256. 
     *
     *  Requirements:
     *  - The correct amount of ether must be sent with this transaction to successfully mint.
     *
     */
    function mintCharacter(string memory name) public payable {
        if (msg.value < state.price) revert InsufficientAmount();

        if (block.number != state.lastMintedBlock) {
            state.lastMintedBlock = uint32(block.number);
            state.currentBlockTokenIndex = 1;
        } else {
            state.currentBlockTokenIndex = state.currentBlockTokenIndex + 1;
        }


        _mint(msg.sender, 1);

        bytes memory seed = abi.encodePacked(uint256(blockhash(block.number-1))/uint256((uint160(msg.sender)))+state.currentBlockTokenIndex);

        uint32 hp = RandomUtil.randomSeededMinMax(3,10, seed[seed.length-1]);
        uint32 str = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-2]);
        uint32 def = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-3]);
        uint32 dex = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-4]);
        uint32 agi = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-5]);

        state.characters[state.index] = Character(
            msg.sender,
            name,
            state.index,
            1,
            0,
            hp,
            str,
            def,
            dex,
            agi,
            CharacterSeed(
                uint8(seed[seed.length-1]), 
                uint8(seed[seed.length-2]), 
                uint8(seed[seed.length-3]), 
                uint8(seed[seed.length-4]), 
                uint8(seed[seed.length-5])
            )
        );

        emit CharacterCreated(msg.sender, state.index);
        
       state. index = state.index + 1;
    }

    /**
     *
     *  @dev Burns a character NFT. Tokens can only be burned by their owners.
     *
     *  @param id - The ID of the character to burn.
     *
     */
    function burnCharacter(uint256 id) public {
        if (ownerOf(id) != msg.sender) revert NotOwner();

        _burn(id);

        delete state.characters[id];

        emit CharacterBurned(msg.sender, id);
    }
}
