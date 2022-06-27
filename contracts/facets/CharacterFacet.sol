// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { ERC721AQueryable } from "./Character/token/ERC721/extensions/ERC721AQueryable.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { Character, CharacterSkill, CharacterSeed, CharacterMultipliers, ICharacters } from "../interfaces/ICharacters.sol";
import "../interfaces/IEquipment.sol";
import "../utils/RandomUtil.sol";

/**
 *
 *  @title Character Token Contract
 *  
 *  @author kaymo.eth
 *
 *  @dev A highly dynamic ERC-721A implementation facet which creates token that have various RPG-style stats such as hp, strength, dexterity, and so on.
 *  While the primary mechanism for leveling up battle and skill stats for these characters resides within this contract, most other functionality is developed 
 *  elsewhere. This allows for a highly flexible and dynamic NFT which is not limited exclusively to its native contract, and allows for continued development of 
 *  functionality through 3rd party contracts.
 *
 */
contract CharacterFacet is ERC721AQueryable {

    event CharacterCreated(address indexed owner, uint256 indexed cid);
    event CharacterBurned(address indexed owner, uint256 indexed cid);

    error Initialized();
    error AccountLimit();
    error InsufficientAmount();
    error NotOwner();
    error AlreadyEquipped();
    error NotOwnerOfEquipment();
    error NotOperator();

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Not owner");
        _;
    }

    modifier onlyOperator {
        if (LibDiamond.diamondStorage().operators[msg.sender] == false) revert NotOperator();
        _;
    }

    function initialize(address _equipment) public onlyOwner {
        if (state.initialized) revert Initialized();
        state.initialized = true;
        state.equipment = IEquipment(_equipment);
        state._name = "Characters";
        state._symbol = "CHARS";
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
     *  @dev getCharacterEquipment
     *  
     *  @param cid - The cid to query
     *
     *  @return equips - An array containing the characters equipment. In order: [Weapon, Helmet, Body Armor, Gloves, Boots]
     *
     */
    function getCharacterEquipment(uint256 cid) public view returns (Equip[] memory equips) {
        for (uint i; i < 5; i++) {
            equips[i] = (state.characterEquipment[cid][i]);
        }
    }

    /**
     *
     *  @dev Gets a character using cid.
     *
     *  @param cid - The cid of the character to query
     *
     *  @return character - A character object including all stats of a character.
     *
     */
    function getCharacter(uint256 cid) public view returns (Character memory) {
        return state.characters[cid];
    }

    function getCharacterStamina(uint256 cid) public view returns (uint256 max, uint256 current) {
        Character storage character = state.characters[cid];

        max = character.stamina;
        current = max - block.timestamp - state.lastStaminaRefresh[cid];
    }

    /**
     *
     *  @dev Adjusts the account limit for characters.
     *
     *  @param limit - The newly imposed limit to characters per wallet.
     *
     */
    function setAccountLimit(uint256 limit) external onlyOperator {
        state.accountLimit = limit;
    }

    /**
     * 
     *  @dev Equips an item to a given character. This removes the previous equipment and replaces it with new equipment.
     *
     *  Requirements:
     *  - Caller must own the equipment.
     *  - The equipment must not be equipped already.
     *
     *  @param cid - The character to equip
     *
     *  @param equipmentId - The equipment to apply.
     *
     */
    function equipItem(uint256 cid, uint256 equipmentId) public {
        Character storage character = state.characters[cid];

        if (state.equipment.ownerOf(equipmentId) != msg.sender) revert NotOwnerOfEquipment();

        Equip memory equip = state.equipment.getEquipment(equipmentId);

        if (equip.equipped == true) revert AlreadyEquipped();

        Equip memory currentEquipment = state.characterEquipment[cid][equip.slot];

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
     *  @dev Refreshes character stamina for external contract usage. 
     *
     *  @notice Stamina is is based on block number and depletes on each block. 
     *  For example, if the character has 200 stamina and refreshes it starts at 200 stamina. Once 200 blocks have been mined / validated,
     *  their stamina is depleted and needs to be refreshed in order to continue doing actions. 
     *
     *  Due to limitations with the solidity language, it's been decided to offset the management of stamina to 3rd party contracts which 
     *  characters interact with. These contracts will execute this function on behalf of the user whenever they choose to refresh their characters
     *  in whichever actionable contract they are using. This is designed to save gas and to work in tandem with the character ecosystem by reducing
     *  the number of transactions that need to be executed on behalf of the user.
     *
     *  @param cid - The character to refresh
     *
     */
    function refreshStamina(uint256 cid) external onlyOperator {
        state.lastStaminaRefresh[cid] = block.number;
    }

    /**
     *
     *  @dev Primary function for giving characters experience points. This is called by external contracts when tasks are 
     *  completed or enemies and defeated. If a character has sufficient experience points to level up, this function handles 
     *  execution of leveling up.
     *
     *  @param cid - The cid
     *
     *  @param amount - Amount of experience to assign
     *
     */
    function gainExperience(uint256 cid, uint256 amount) public onlyOperator() {
        Character storage character = state.characters[cid];

        character.exp = character.exp + amount;

        if (character.exp > toNextLevel(character.level)) {
            _gainLevel(character);
        }
    }

    function gainTradeExperience(uint256 cid, uint256 skillId, uint256 amount) public onlyOperator {
        Character storage character = state.characters[cid];

        if (skillId == 1) {
            character.mining.exp = character.mining.exp + amount;
            if (character.mining.exp > toNextLevel(character.mining.level)) _gainSkillLevel(character, skillId);
        } else if (skillId == 2) {
            character.fishing.exp = character.mining.exp + amount;
            if (character.fishing.exp > toNextLevel(character.fishing.level)) _gainSkillLevel(character, skillId);
        } else if (skillId == 3) {
            character.woodcutting.exp = character.mining.exp + amount;
            if (character.woodcutting.exp > toNextLevel(character.woodcutting.level)) _gainSkillLevel(character, skillId);
        } else if (skillId == 4) {
            character.stonecutting.exp = character.mining.exp + amount;
            if (character.stonecutting.exp > toNextLevel(character.stonecutting.level)) _gainSkillLevel(character, skillId);
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
    function toNextLevel(uint256 level) public pure returns (uint256) {
        return (((4 * level ** 2) / 5) + 50) * 1e18;
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
        if (balanceOf(msg.sender) >= state.accountLimit) revert AccountLimit();

        if (block.number != state.lastMintedBlock) {
            state.lastMintedBlock = uint32(block.number);
            state.currentBlockTokenIndex = 1;
        } else {
            state.currentBlockTokenIndex = state.currentBlockTokenIndex + 1;
        }

        _mint(msg.sender, 1);

        /// Hacky Pseudorandom seed.
        bytes memory seed = abi.encodePacked(uint256(blockhash(block.number-1))/uint256((uint160(msg.sender)))+state.currentBlockTokenIndex);

        uint256 hp = 10  + ((seed.length - 1) / 255);
        uint256 str = 3 + ((seed.length - 2) / 255);
        uint256 def = 3 + ((seed.length - 3) / 255);
        uint256 dex = 3 + ((seed.length - 4) / 255);
        uint256 agi = 3 + ((seed.length - 5) / 255);

        state.characters[state.index] = Character(
            msg.sender,
            name,
            state.index,
            1,
            0,
            250,
            hp,
            str,
            def,
            dex,
            agi,
            CharacterSkill(1,0),
            CharacterSkill(1,0),
            CharacterSkill(1,0),
            CharacterSkill(1,0),
            CharacterMultipliers(1e18,1e18,1e18,1e18)
        );
        
        state.seeds[state.index] = CharacterSeed(
                uint8(seed[seed.length-1]), 
                uint8(seed[seed.length-2]), 
                uint8(seed[seed.length-3]), 
                uint8(seed[seed.length-4]), 
                uint8(seed[seed.length-5])
            );

        emit CharacterCreated(msg.sender, state.index);
        
        state.index = state.index + 1;
    }
/*
    function updateCharacterStamina(uint256 cid, uint256 staminaAmount) external onlyOperator {
        Character storage character = state.characters[cid];
        character.stamina = character.stamina + staminaAmount;
    }

    function updateCharacterMultipliers(uint256 cid, uint256[] memory multipliers) external onlyOwner {
        Character storage character = state.characters[cid];

        if (multipliers[0] > 0) {
            character.multipliers.speed = character.multipliers.speed + multipliers[0];
        }

        if (multipliers[1] > 0) {
            character.multipliers.exp = character.multipliers.exp + multipliers[1];
        }

        if (multipliers[2] > 0) {
            character.multipliers.gems = character.multipliers.gems + multipliers[2];
        }

        if (multipliers[3] > 0) {
            character.multipliers.drops = character.multipliers.drops + multipliers[3];
        }
    }
*/
    /**
     *
     *  @dev Burns a character NFT. Tokens can only be burned by their owners.
     *
     *  @param cid - The ID of the character to burn.
     *
     */
    function burnCharacter(uint256 cid) public {
        if (ownerOf(cid) != msg.sender) revert NotOwner();

        _burn(cid);

        delete state.characters[cid];

        emit CharacterBurned(msg.sender, cid);
    }

    /**
     *
     *  @dev Handles incrementing a characters level. This removes the experience cost from the characters exp pool and then increments 
     *  their level and stats accordingly.
     *
     *  Level gaining is capped at 20 per action. This is to ensure the transactions success, as higher limitations will possibly
     *  result in failure. Such circumstances should be rare, but this helps remedy edge cases where characters have an extravagant 
     *  amount of experience pooled and haven't completed an action in some time.
     *
     *  @param character - The character object to update.
     *
     */
    function _gainLevel(Character storage character) private {
        uint i;

        while (i < 20 && character.exp > toNextLevel(character.level)) {
            character.exp = character.exp - toNextLevel(character.level);
            character.level = character.level + 1;
            i++;
        }

        CharacterSeed memory seed = state.seeds[character.id];

        character.hp = ((character.level * (character.level -1)) / 3) + (seed.hp * character.level / 255) + 10;
        character.str = ((character.level * (character.level -1)) / 15) + (seed.str * character.level / 255) + 3;
        character.dex = ((character.level * (character.level -1)) / 15) + (seed.dex * character.level / 255) + 3;
        character.agi = ((character.level * (character.level -1)) / 15) + (seed.agi * character.level / 255) + 3;
        character.def = ((character.level * (character.level -1)) / 15) + (seed.def * character.level / 255) + 3;
    }

    /**
     *
     *  @dev This levels a tradeskill. Function needs to be improved.
     *
     */
    function _gainSkillLevel(Character storage character, uint256 skillId) internal {
        uint i;
         if (skillId == 1) {
            while (i < 20 && character.mining.exp > toNextLevel(character.mining.level)) {
                character.mining.exp = character.mining.exp - toNextLevel(character.mining.level);
                character.mining.level = character.mining.level + 1;
            }
        } else if (skillId == 2) {
            while (i < 20 && character.fishing.exp > toNextLevel(character.fishing.level)) {
                character.fishing.exp = character.fishing.exp - toNextLevel(character.fishing.level);
                character.fishing.level = character.fishing.level + 1;
            }
        } else if (skillId == 3) {
            while (i < 20 && character.woodcutting.exp > toNextLevel(character.woodcutting.level)) {
                character.woodcutting.exp = character.woodcutting.exp - toNextLevel(character.woodcutting.level);
                character.woodcutting.level = character.woodcutting.level + 1;
            }
        } else if (skillId == 4) {
            while (i < 20 && character.stonecutting.exp > toNextLevel(character.stonecutting.level)) {
                character.stonecutting.exp = character.stonecutting.exp - toNextLevel(character.stonecutting.level);
                character.stonecutting.level = character.stonecutting.level + 1;
            }
        }
    }  

    /**
     *
     *  @dev _transfer override. This simply checks if the receiving account will have more than the account limit before executing the transfer.
     *
     *  @param from - The address the token is sent from.
     *
     *  @param to - The address the token is sent to.
     *
     *  @param tokenId - The tokenId being sent.
     *
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (balanceOf(to) + 1 > state.accountLimit) revert AccountLimit();
        super._transfer(from, to, tokenId);
    }
}
