// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./token/ERC721/ERC721A.sol";
import "./token/ERC721/extensions/ERC721AQueryable.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/IEquipment.sol";
import "./access/Operator.sol";
import "./utils/RandomUtil.sol";

/***
 *
 *  @title Character (Unnamed)
 *  
 *  @author kaymo.eth
 *  @version 0.0.1
 *  
 *  @dev  An unnamed gaming project developed to be a highly dynamic and flexible yet simplistic character based NFT.
 *  Characters are usable on blockchain and utility contracts can be created and use characters as plug-and-playable assets or in-game characters.
 *
 *
 */
contract Characters is ICharacters, ERC721A, ERC721AQueryable, Operator {

    uint256 public price = 0.0001 ether;
    uint256 public index;

    IEquipment equipment;

    uint32 firstMintedOfLastBlock;
    uint32 currentBlockTokenIndex;
    uint32 lastMintedBlock;
    
    mapping (uint256 => Character) public characters;
    mapping (uint256 => mapping(uint256 => Equip)) characterEquipment;

    constructor() ERC721A("Character","Character") {}

    function initialize(address _equipment) public onlyOperator {
        equipment = IEquipment(_equipment);
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
        Character storage character = characters[characterId];

        if (equipment.ownerOf(equipmentId) != msg.sender) revert NotOwnerOfEquipment();

        Equip memory equip = equipment.getEquipment(equipmentId);

        if (equip.equipped == true) revert AlreadyEquipped();

        Equip memory currentEquipment = characterEquipment[characterId][equip.slot];

        character.hp = character.hp + equip.hp - currentEquipment.hp;
        character.str = character.str  + equip.str - currentEquipment.str;
        character.def = character.def + equip.def - currentEquipment.def;
        character.agi = character.agi + equip.agi - currentEquipment.agi;
        character.dex = character.dex + equip.dex - currentEquipment.dex;

        // Set equipment statuses.
        equipment.setEquipped(equipmentId, true);
        equipment.setEquipped(currentEquipment.id, false);
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
            equips[i] = (characterEquipment[id][i]);
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
    function gainExperience(uint256 id, uint32 amount) public onlyOperator() {
        Character storage character = characters[id];

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
            chars[i] = (characters[tokens[i]]);
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
            chars[i] = (characters[tokens[i]]);
            
            for (uint j = 0; j < 5; j++) {
                equips[j] = characterEquipment[i][j];
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
        return characters[id];
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
        if (msg.value < price) revert InsufficientAmount();

        if (block.number != lastMintedBlock) {
            lastMintedBlock = uint32(block.number);
            currentBlockTokenIndex = 1;
        } else {
            currentBlockTokenIndex = currentBlockTokenIndex + 1;
        }


        _mint(msg.sender, 1);

        bytes memory seed = abi.encodePacked(uint256(blockhash(block.number-1))/uint256((uint160(msg.sender)))+currentBlockTokenIndex);

        uint32 hp = RandomUtil.randomSeededMinMax(3,10, seed[seed.length-1]);
        uint32 str = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-2]);
        uint32 def = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-3]);
        uint32 dex = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-4]);
        uint32 agi = RandomUtil.randomSeededMinMax(2,7, seed[seed.length-5]);

        characters[index] = Character(
            msg.sender,
            name,
            index,
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

        emit CharacterCreated(msg.sender, index);
        
        index = index + 1;
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

        delete characters[id];

        emit CharacterBurned(msg.sender, id);
    }
}