// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


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
    mapping (uint256 => Area) areas;
    mapping (uint256 => uint256) characterLocation;

    struct Area { 
        uint256 difficulty;
        uint256 index;
        uint256 expRate;
        uint256 dropRate;
        uint256 gemRate;
        mapping(uint256 => uint256) lastTimeUpdated;
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
    function getOwnedCharactersInAreas(address owner) 
    external view returns (Character[] memory, uint256[] memory) {
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
     *  @param _difficulty - The difficult of the area.
     *
     *  Areas MUST be created in sequential order starting at 1.
     *
     */
    function createArea(
        uint256 areaID, 
        uint256 _difficulty, 
        uint256 dailyExp, 
        uint256 dailyDrops, 
        uint256 dailyGems
    ) external onlyOperator {
        if (index < areaID) index = areaID;

        Area storage area = areas[areaID];

        area.difficulty = _difficulty;
        area.expRate = dailyExp / 86400;
        area.dropRate = dailyDrops / 86400;
        area.gemRate = dailyGems / 86400;

        if (index < areaID) index = areaID;

        emit AreaCreated(areaID);
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

    function difficulty(uint256 areaID) external view returns (uint256) {
        return areas[areaID].difficulty;
    }
    
    function expRate(uint256 areaID) external view returns (uint256) {
        return areas[areaID].expRate;
    }

    function dropRate(uint256 areaID) external view returns (uint256) {
        return areas[areaID].dropRate;
    }

    function gemRate(uint256 areaID) external view returns (uint256) {
        return areas[areaID].gemRate;
    }

    function getSuccessRate(uint256 areaID, uint256 characterID) external view returns (uint256) {
        return areas[areaID].successRate[characterID];
    }

    function getExpPerHour(uint256 areaID, uint256 characterID) external view returns (uint256) {
        Area storage area = areas[areaID];

        return ((area.expRate * area.successRate[characterID]) / 1e18) * 3600;
    }

    function getGoldPerHour(uint256 areaID, uint256 characterID) external view returns (uint256) {
        Area storage area = areas[areaID];
        return (area.gemRate * area.successRate[characterID]) * 3600;
    }

    function getAvailableExp(uint256 areaID, uint256 characterID) external view returns (uint256) {
        Area storage area = areas[areaID];
        uint256 lastUpdated = area.lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        return (timeBattling * area.expRate * area.successRate[characterID]) / 1e18;
    }

    function getAvailableGold(uint256 areaID, uint256 characterID) external view returns (uint256) {
        Area storage area = areas[areaID];

        uint256 lastUpdated = area.lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        return timeBattling * area.gemRate * area.successRate[characterID];
    }

    function enter(uint256 areaID, uint256 characterID) public {
        Area storage area = areas[areaID];
        IERC721(characters).transferFrom(msg.sender, address(this), characterID);

        // Assigns the characterID to the newly minted token.
        // This saves gas setting IDs while also making it a lot easier to understand which token it represents.
        _mint(msg.sender, characterID);

        _setAreaSuccessRate(areaID, characterID);

        area.lastTimeUpdated[characterID] = block.timestamp;

        emit AreaEntered(msg.sender, characterID);
    }

    /**
     *
     *  @dev Exits the area. This removes the character from the contract and burns the token which represents them here as a receipt.
     *  
     *  @notice A receipt token is required to withdraw a character from this contract.
     *
     *  @param characterID - The ID of the token to withdraw. This is the same tokenID as the token which is used to claim it.
     *
     */
    function exit(uint256 areaID, uint256 characterID) public {
        Area storage area = areas[areaID];

        // This is sufficient for determining if the character is in the area or not.
        if (area.lastTimeUpdated[characterID] == 0) return;

        _burn(characterID);

        IERC721(characters).transferFrom(address(this), msg.sender, characterID);

        area.lastTimeUpdated[characterID] = 0;
    }

    /**
     *
     *  @dev Calculates the success rate that a character will have for each battle they engage in while in this area.
     *  This is used to calculate the reward rate for a character.
     *
     *  @param characterID - CharacterID
     *
     */
    function _setAreaSuccessRate(uint256 areaID, uint256 characterID) public {
        Area storage area = areas[areaID];
        Character memory character = ICharacters(characters).getCharacter(characterID);

        uint256 power = sqrt(character.hp * character.str * character.dex * character.agi * character.def);

        uint256 successPercentile = power * 1e18 / area.difficulty;
        
        if (successPercentile < 750_000_000_000_000_000) {
            area.successRate[characterID] = 0;
        } else if (successPercentile > 1e18) {
            area.successRate[characterID] = 1e18;
        }
    }

    /**
     */
    function refresh(uint256 id) public {

    }

    /**
     *  Gets the currently set variables for a character based on their success rate in an area.
     */
    function testRates(uint256 areaID, uint256 characterID) public view returns (uint256, uint256) {
        Area storage area = areas[areaID];

        uint256 lastUpdated = area.lastTimeUpdated[characterID];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * area.expRate * area.successRate[characterID]) / 1e18);

        uint256 drop = timeBattling * area.dropRate * area.successRate[characterID];

        return (experience, drop);
    }

    /**
     *
     *  @dev Handles distribution of experience and loot to character.
     *
     *  @param characterID - The characterID to give loot and experience to.
     *
     *
     */
    function _getExperienceAndGems(uint256 areaID, uint256 characterID) internal {
        Area storage area = areas[areaID];
        uint256 lastUpdated = area.lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        uint32 experienceGained = uint32((timeBattling * area.expRate * area.successRate[characterID]) / 1e18);
        uint256 goldGained = timeBattling * area.dropRate * area.successRate[characterID];

        /// Assign exp to character
        ICharacters(characters).gainExperience(characterID, experienceGained);

        /// Mint gold to character owner.
        IGems(gems).mintTo(msg.sender, goldGained);

        /// Update characters last update time. This ensures they don't claim additional rewards.
        area.lastTimeUpdated[characterID] = block.timestamp;

        /// Resets their success rate incase they have leveled up.
        _setAreaSuccessRate(areaID, characterID);

        emit ExperienceAndGoldGained(characterID, experienceGained, goldGained);
    }

    /**
     *
     *  @dev Collects rewards based on time spent in the area.
     *
     */
    function collect(uint256 areaID, uint256 characterID) public {
        if (ownerOf(characterID) != msg.sender) revert NotOwner();
        _getExperienceAndGems(areaID, characterID);
    }

    /**
     *
     *  @dev Characters who are in this area generate experience automatically over time. Experience can be claimed here, or automatically upon exiting the area.
     *  If you are in this area for an extended period of time, it can be useful to claim experience before you leave, so that you are able to level up.
     *  
     *  @param characterID - The characterID which is claiming this experience.
     *
     */
    function collectExperience(uint256 areaID, uint256 characterID) public {
        if (ownerOf(characterID) != msg.sender) revert NotOwner();

        Area storage area = areas[areaID];
        uint256 lastUpdated = area.lastTimeUpdated[characterID];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * area.expRate * area.successRate[characterID]) / 1e18);

        ICharacters(characters).gainExperience(characterID, experience);

        area.lastTimeUpdated[characterID] = block.timestamp;
    }
}