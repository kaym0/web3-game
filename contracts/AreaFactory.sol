// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./access/Operator.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/IGems.sol";
import "./interfaces/IArea.sol";

contract AreaFactory is ERC721Enumerable, Operator, IArea {
    address public characters;
    address public gems;

    uint256 public index;
    uint256 public baseSpeed = 10e18;

    mapping (uint256 => Area) areas;
    mapping (uint256 => uint256) characterLocation;
    mapping(uint256 => uint256) lastTimeUpdated;

    struct Area { 
        uint256 difficulty;
        uint256 index;
        uint256 expRate;
        uint256 dropRate;
        uint256 gemRate;
        mapping(uint256 => uint256) successRate;
    }

    constructor(address _characters, address _gems) ERC721("Emerald Forest", "Area-1")  {
        characters = _characters;
        gems = _gems;
    }

    /**
     *  Fetches all characters of an owner, returning with them the area in which it's staked.
     *  This is expected to be incredibly heavy on gas and this will be removed for alternative
     *  methods in the future.
     */
    function getOwnedCharactersInAreas(address owner) external view returns (Character[] memory, uint256[] memory) {
        uint256 tokensOwned = balanceOf(owner);

        Character[] memory owned = new Character[](tokensOwned);
        uint256[] memory characterAreas = new uint256[](tokensOwned);

        for (uint i; i < tokensOwned; i++) {
            uint256 id = tokenOfOwnerByIndex(owner,i);
            owned[i] = ICharacters(characters).getCharacter(id);
            characterAreas[i] = characterLocation[id];
        }

        return (owned, characterAreas);
    }

    /**
     *
     *  @dev Creates a new area, where characters can go to battle and win rewards.
     *
     *   Rates are calculted using the base amount of actions completed a day. This is calculated based on the base number of actions per day. 
     *
     *  @param _difficulty - The difficult of the area.
     *
     *  Areas MUST be created in sequential order starting at 1.
     *
     */
    function createArea(
        uint256 areaId, 
        uint256 _difficulty, 
        uint256 dailyExp, 
        uint256 dailyGems,
        uint256 dailyDrops 
    ) external onlyOperator {
        Area storage area = areas[areaId];

        area.difficulty = _difficulty;

        /// Experience per battle.
        area.expRate = (dailyExp * 1e18) / (86400 / (baseSpeed / 1e18));

        /// Gems per battle
        area.gemRate = (dailyGems * 1e18) / (86400 / (baseSpeed / 1e18));

        /// Droprate per battle
        area.dropRate = (dailyDrops * 1e18) / (86400 / (baseSpeed / 1e18));

        if (index < areaId) index = areaId;

        emit AreaCreated(areaId);
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function population() public view returns (uint256) {
        return IERC721(characters).balanceOf(address(this));
    }

    function difficulty(uint256 areaId) external view returns (uint256) {
        return areas[areaId].difficulty;
    }
    
    function expRate(uint256 areaId) external view returns (uint256) {
        return areas[areaId].expRate;
    }

    function dropRate(uint256 areaId) external view returns (uint256) {
        return areas[areaId].dropRate;
    }

    /**
     *
     *  @dev Fetches the standard gem rate for the area. This is the base rate and is not influenced by character buffs or success rate.
     * 
     */
    function gemRate(uint256 areaId) external view returns (uint256) {
        return areas[areaId].gemRate;
    }

    function getSuccessRate(uint256 areaId, uint256 cid) external view returns (uint256) {
        return areas[areaId].successRate[cid];
    }

    /**
     *
     *  @dev Fetches the amount of experiecne a character will receive in an area after spending one hour.
     *  Since this is character dependant, it may vary between characters.
     *
     *  @param areaId - Area ID
     *
     *  @param cid - Character ID
     *
     *  @return gemsPerHour - Amount of experience a character should receive for one hour spent within the area.
     *
     */
    function getExpPerHour(uint256 areaId, uint256 cid) external view returns (uint256) {
        Area storage area = areas[areaId];
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return area.expRate * area.successRate[cid] * actionsPerHour / 1e18;
    }

    /**
     *
     *  @dev Fetches the amount of gems a character will receive in an area after spending one hour.
     *  Since this is character dependant, it may vary between characters.
     *
     *  @param areaId - Area ID
     *
     *  @param cid - Character ID
     *
     *  @return gemsPerHour - Amount of gems a character should receive for one hour spent within the area.
     *
     */
    function getGemsPerHour(uint256 areaId, uint256 cid) external view returns (uint256) {
        Area storage area = areas[areaId];

        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return (area.gemRate * area.successRate[cid]) * actionsPerHour / 1e18;
    }

    /**
     *
     *  @dev See getAvailableGemsAndExp(). 
     *  Fetches the total experience available for a given character. 
     *
     *  @param areaId - Area ID
     *
     *  @param cid - Character ID
     *
     *  @return expGained - Experience available for character at cid.
     *
     */
    function getAvailableExp(uint256 areaId, uint256 cid) external view returns (uint256 expGained) {
        (expGained,) = getAvailableExpAndGems(areaId, cid);
    }

    /**
     *
     *  @dev See getAvailableGemsAndExp(). 
     *  Fetches the total gems available for a given character. 
     *
     *  @param areaId - Area ID
     *
     *  @param cid - Character ID
     *
     *  @return gemsGained - Gems available for character at cid.
     *
     */
    function getAvailableGems(uint256 areaId, uint256 cid) external view returns (uint256 gemsGained) {
        (,gemsGained) = getAvailableExpAndGems(areaId, cid);
    }

    /**
     *
     *  @dev Fetches the currently available experience and gems that a character has earned while in the area. This accounts
     *  for stamina, and will cease to increase after the characters stamina reaches zero.
     *
     *  @param areaId - The area ID
     *
     *  @param cid - The character ID
     *
     *  @return expGained - Experience gained
     *
     *  @return gemsGained - Gems gained.
     *
     */
    function getAvailableExpAndGems(uint256 areaId, uint256 cid) public view returns (uint256 expGained, uint256 gemsGained) {
        Area storage area = areas[areaId];
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint lastUpdate = lastTimeUpdated[cid];

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 timeSinceLast = character.stamina * 10  > block.timestamp - lastUpdate ? block.timestamp - lastUpdate : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        expGained  = actionsSinceLast * area.expRate * area.successRate[cid] / 1e18;
        gemsGained = actionsSinceLast * area.gemRate * area.successRate[cid] / 1e18;  
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

    /**
     *
     *  @dev Moves a character into an area. This begins battling and rewards are earned from this point forward. Characters will run out of
     *  stamina and cease to get rewards beyond a certain point, at this point, the refresh() function can be called to fully restore stamina.
     *
     *  An NFT is minted to the owner and is used as a receipt when leaving the area. Only the owner of the receipt area NFT will be capable of
     *  claiming a character back from an area. It is highly recommended not to trade or transfer area NFTs and to instead withdraw characters
     *  from an area before executing any sort of trade or transfer involving the character.
     *
     *  @param areaId - The area id
     *
     *  @param cid - The character id
     *
     */
    function enter(uint256 areaId, uint256 cid) public {
        IERC721(characters).transferFrom(msg.sender, address(this), cid);

        // Assigns the cid to the newly minted token.
        // This saves gas setting IDs while also making it a lot easier to understand which token it represents.
        _mint(msg.sender, cid);

        _setAreaSuccessRate(areaId, cid);

        lastTimeUpdated[cid] = block.timestamp;

        characterLocation[cid] = areaId;

        emit AreaEntered(msg.sender, cid);
    }

    /**
     *
     *  @dev Exits the area. This removes the character from the contract and burns the token which represents them here as a receipt.
     *  
     *  @notice A receipt token is required to withdraw a character from this contract.
     *
     *  @param cid - The ID of the token to withdraw. This is the same tokenID as the token which is used to claim it.
     *
     */
    function exit(uint256 cid) public {
        // This is sufficient for determining if the character is in the area or not.
        if (lastTimeUpdated[cid] == 0) return;

        _burn(cid);

        IERC721(characters).transferFrom(address(this), msg.sender, cid);

        delete lastTimeUpdated[cid];
        delete characterLocation[cid];
    }

    /**
     *
     *  @dev Calculates the success rate that a character will have for each battle they engage in while in this area.
     *  This is used to calculate the reward rate for a character.
     *
     *  @param cid - CharacterID
     *
     */
    function _setAreaSuccessRate(uint256 areaId, uint256 cid) public {
        Area storage area = areas[areaId];
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint256 power = sqrt(character.hp * character.str * character.dex * character.agi * character.def);

        uint256 successPercentile = power * 1e18 / area.difficulty;
        
        if (successPercentile < 750_000_000_000_000_000) {
            area.successRate[cid] = 0;
        } else if (successPercentile > 1e18) {
            area.successRate[cid] = 1e18;
        } else {
            area.successRate[cid] = successPercentile;
        }
    }

    /**
     *  Gets the currently set variables for a character based on their success rate in an area.
     */
    function testRates(uint256 areaId, uint256 cid) public view returns (uint256, uint256) {
        Area storage area = areas[areaId];

        uint256 lastUpdated = lastTimeUpdated[cid];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 _expRate = uint32((timeBattling * area.expRate * area.successRate[cid]) / 1e18);

        uint256 _gemRate = timeBattling * area.dropRate * area.successRate[cid] / 1e18;

        return (_expRate, _gemRate);
    }

    /**
     *
     *  @dev Handles distribution of experience and loot to character for battling within the area. Characters are 
     *  limited by their stamina pool and only receive rewards for the period for which they have enoughs stamina to
     *  sustain battle. Stamina is recovered by collecting experience within the area a character is battling.
     *
     *  @param areaId - ID of the area being collected for.
     *
     *  @param cid - The cid to give loot and experience to.
     *
     */
    function _getExperienceAndGems(uint256 areaId, uint256 cid) internal {
        /// Calculate experience and gem values
        (uint256 expGained, uint256 gemsGained) = getAvailableExpAndGems(areaId, cid);

        /// Assign exp to character
        ICharacters(characters).gainExperience(cid, expGained);

        /// Mint gems to character owner.
        IGems(gems).mintTo(msg.sender, gemsGained);

        /// Update characters last update time. This ensures they don't claim additional rewards.
        lastTimeUpdated[cid] = block.timestamp;

        /// Resets their success rate incase they have leveled up.
        _setAreaSuccessRate(areaId, cid);

        emit ExperienceAndGemsGained(cid, expGained, gemsGained);
    }


    /**
     *
     *
     *  Temporary function which will be removed.
     *
     *
     */
    function __getExperienceAndGems(uint256 areaId, uint256 cid) internal {
        Area storage area = areas[areaId];
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint lastUpdate = lastTimeUpdated[cid];

        /// Calculation is used several times in this tx, so this saves gas.
        uint256 characterSpeed = (baseSpeed - ((baseSpeed * character.multipliers.speed) / 1e18) / 2);

        uint256 timeSinceLast = character.stamina * 10  > block.timestamp - lastUpdate ? block.timestamp - lastUpdate : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        uint experienceGained = actionsSinceLast * area.expRate * area.successRate[cid] / 1e18;

        uint gemsGained = actionsSinceLast * area.gemRate * area.successRate[cid] / 1e18;

        /// Assign exp to character
        ICharacters(characters).gainExperience(cid, uint32(experienceGained));

        /// Mint gems to character owner.
        IGems(gems).mintTo(msg.sender, gemsGained);

        /// Update characters last update time. This ensures they don't claim additional rewards.
        lastTimeUpdated[cid] = block.timestamp;

        /// Resets their success rate incase they have leveled up.
        _setAreaSuccessRate(areaId, cid);

        emit ExperienceAndGemsGained(cid, experienceGained, gemsGained);
    }

    /**
     *
     *  @dev Collects rewards based on time spent in the area. This executes a series of complex calculations and should only be executed when stamina is low.
     *  This will help reduce network load and reduce upfront costs for leveling your character and earning gems.
     *
     */
    function collect(uint256 areaId, uint256 cid) public {
        if (ownerOf(cid) != msg.sender) revert NotOwner();

        _getExperienceAndGems(areaId, cid);
        ICharacters(characters).refreshStamina(cid);
    }

    /**
     *
     *  @dev Characters who are in this area generate experience automatically over time. Experience can be claimed here, or automatically upon exiting the area.
     *  If you are in this area for an extended period of time, it can be useful to claim experience before you leave, so that you are able to level up.
     *  
     *  @param cid - The cid which is claiming this experience.
     *
     */
    function collectExperience(uint256 areaId, uint256 cid) public {
        if (ownerOf(cid) != msg.sender) revert NotOwner();

        Area storage area = areas[areaId];
        uint256 lastUpdated = lastTimeUpdated[cid];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * area.expRate * area.successRate[cid]) / 1e18);

        ICharacters(characters).gainExperience(cid, experience);

        lastTimeUpdated[cid] = block.timestamp;
    }
}