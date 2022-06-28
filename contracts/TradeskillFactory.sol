// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./access/Operator.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/ITradeskillToken.sol";
import "./interfaces/ITradeskill.sol";

contract TradeskillFactory is ERC721Enumerable, Operator, ITradeskill {
    address public characters;

    mapping (uint256 => uint256) public lastTimeUpdated;
    mapping (uint256 => uint256) public characterLocation;
    mapping (uint256 => address) public materialContracts;

    uint256 public baseSpeed = 10e18;

    event TradeskillActive(uint256 skillId, uint256 cid);
    event TradeskillInactive(uint256 skillId, uint256 cid);

    error NotOwner(string errorMsg);
    error NotAtLocation(string errorMsg);
    error SkillDoesNotExist(string errorMsg);

    constructor(address _characters ) ERC721("Tradeskill", "TradeSkill") {
        characters = _characters;
    }


    /**
     *  Fetches all characters of an owner, returning with them the tradeskill in which it's staked.
     *  This is expected to be incredibly heavy on gas and this will be removed for alternative
     *  methods in the future.
     */
    function getOwnedCharacters(address owner) external view returns (Character[] memory, uint256[] memory) {
        uint256 tokensOwned = balanceOf(owner);

        Character[] memory owned = new Character[](tokensOwned);
        uint256[] memory charactersInTradeskill = new uint256[](tokensOwned);

        for (uint i; i < tokensOwned; i++) {
            uint256 id = tokenOfOwnerByIndex(owner,i);
            owned[i] = ICharacters(characters).getCharacter(id);
            charactersInTradeskill[i] = characterLocation[id];
        }

        return (owned, charactersInTradeskill);
    }

    /**
     *
     *  @dev Adds a tradeskill that is useable to all users to this contract. Requires a reward material and the ability to mint tokens from
     *  the material contract.
     *
     *  @notice The index begins at 1; 0 will be used to determine a character is NOT in an area.
     *
     *  @param skillId - The ID of the skill being added
     *
     *  @param materialContract - The material contract. This contract must be approved for minting through that contract.
     *
     */
    function updateTradeskill(uint256 skillId, address materialContract) external onlyOperator {
        require(skillId != 0, "Cannot use zero for index");
        materialContracts[skillId] = materialContract;
    }

    /**
     *
     *  @dev Updates the base speed. This is the maximum amount of time an action will take for characters to execute.
     *
     */
    function updateBaseSpeed(uint256 speed) external onlyOperator {
        baseSpeed = speed;
    }

    /**
     *
     *  @dev Fetches the hourly experience a character will receive.
     *
     */
    function getHourlyExperience(uint256 cid, uint256 skillId) external view override returns (uint256) {
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return 1e17 * actionsPerHour;
    }

    /**
     *
     *  @dev Fetches the hourly amount of materials a character will receive.
     *
     */
    function getHourlyMaterials(uint256 cid, uint256 skillId) external view override returns (uint256) {
        Character memory character = ICharacters(characters).getCharacter(cid);
        
        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return _totalMaterials(skillId, character, actionsPerHour);
    }

    /**
     *
     *  @dev Fethces the currently available amount of experience a character has earned and is able to claim.
     *
     *  See: getAvailableExpAndMaterials()
     *
     */
    function getAvailableExperience(uint256 cid) public view override returns (uint256 experienceGained) {
        (experienceGained,) = getAvailableExpAndMaterials(cid);
    }
    /**
     *
     *  @dev Fethces the currently available amount of materials a character has earned and is able to claim.
     *
     *  See: getAvailableExpAndMaterials()
     *
     */
    function getAvailableMaterials(uint256 cid) public view override returns (uint256 materialsGained) {
        (,materialsGained) = getAvailableExpAndMaterials(cid);
    }

    /**
     *
     *  @dev getAvailableExpAndMaterials 
     *
     *  @param cid - Character ID 
     *
     *  @return expGained - The amount of exp the selected character has earned and is able to claim.
     *
     *  @return materialsGained - The amount of materials the selected character has earned and is able to claim.
     *
     */
    function getAvailableExpAndMaterials(uint256 cid) public view override returns (uint256 expGained, uint256 materialsGained) {
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 skillId = characterLocation[cid];

        uint256 lastUpdate = lastTimeUpdated[cid];

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 timeSinceLast = character.stamina * 10  > block.timestamp - lastUpdate ? block.timestamp - lastUpdate : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        expGained  = actionsSinceLast * 1e17;
        materialsGained =  _totalMaterials(skillId, character, actionsSinceLast);
    }

    /**
     *
     *  @dev Fetches values that are associated with the characters stamina; This is designed to simplify the front-end logic when determining
     *  how much time a character has been battling.
     *
     *  @param cid - The character ID to query.
     *
     *  @return lastTimeUpdated - The last block where the character restored their stamina.
     *
     *  @return currentBlock - The current block number.
     *
     */
    function characterBlockInfo(uint256 cid) external view returns (uint256, uint256) {
        return (
            lastTimeUpdated[cid],
            block.timestamp
        );
    }

    function collect(uint256 cid) external override {   

        if (ownerOf(cid) != _msgSender()) revert NotOwner("Tradeskill Factory: Not owner");
    
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 skillId = characterLocation[cid];

        // Calculates character mining speed based on their multipliers.
        uint256 characterSpeed = (baseSpeed - ((baseSpeed * character.multipliers.speed) / 1e18) / 2);

        /// Calculates the effective time since last claim; If the users effective stamina time is greater than the actual time, the actual time is used.
        /// If the stamina is less than, the stamina is used. This is to limit based on stamina amounts,
        uint256 timeSinceLast = 
        character.stamina * 10  > block.timestamp - lastTimeUpdated[cid] 
            ? block.timestamp - lastTimeUpdated[cid] 
            : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        uint256 totalMaterials = _totalMaterials(skillId, character, actionsSinceLast);

        uint256 experienceGained = actionsSinceLast * 1e17;

        /// Mint the associated skill materials to the caller.
        ITradeskillToken(materialContracts[skillId]).mintTo(_msgSender(), totalMaterials);

        /// Apply experience to character.
        ICharacters(characters).gainTradeExperience(cid, skillId, experienceGained );

        /// Updates the characters timestmap, refreshing their stamina.
        lastTimeUpdated[cid] = block.timestamp;
    }

    /**
     *
     *  @dev Starts tradeskill. The character is moved to this contract and a replacement NFT is given to the owner.
     *
     *  Requirements:
     *  - The character must be owned by the caller.
     *  - The character must not be actively performing another in-game action such as battling.
     *  - This contract must be approved to transfer the character.
     *
     *  @param skillId - The skill to perform.
     *
     *  @param cid - The character ID.
     *
     */
    function start(uint256 skillId, uint256 cid) external override {
        if (skillId < 1 || skillId > 4) revert SkillDoesNotExist("Tradeskill Factory: This skill does not exist");
        
        IERC721(characters).transferFrom(_msgSender(), address(this), cid);

        /// Mints a receipt NFT for the character which is performing tradeskill. This is used to claim the character in the future.
        _mint(msg.sender, cid);

        /// Sets the last time the character was updated to now. This is used for stamina calculations 
        lastTimeUpdated[cid] = block.timestamp;
        
        /// Sets the character location, so this contract knows which rewards it is entitled to.
        characterLocation[cid] = skillId;

        emit TradeskillActive(skillId, cid);
    }

    function stop(uint256 cid) external override {
        if (ownerOf(cid) != _msgSender()) revert NotOwner("Tradeskill Factory: Not Owner");

        _burn(cid);
        
        IERC721(characters).transferFrom(address(this), _msgSender(), cid);

        delete characterLocation[cid];
        delete lastTimeUpdated[cid];

        emit TradeskillInactive(characterLocation[cid], cid);
    }


    function _totalMaterials(uint256 skillId, Character memory character, uint256 actionsSinceLast) internal pure returns (uint256) {
        if (skillId == 1) {
            return (((character.mining.level / 5) + 1) * actionsSinceLast) * 1e18;
        } else if (skillId == 2) {
            return (((character.fishing.level / 5) + 1) * actionsSinceLast) * 1e18;
        } else if (skillId == 3) {
            return (((character.woodcutting.level / 5) + 1) * actionsSinceLast) * 1e18;
        } else if (skillId == 4) {
            return (((character.stonecutting.level / 5) + 1) * actionsSinceLast) * 1e18;
        }
        return 0;
    }
}