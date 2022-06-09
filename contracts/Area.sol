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

/**
 *
 *  @title Area
 *  
 *  @author kaymo.eth
 *
 *  @dev A combat zone in a nameless game. Characters can be placed into the area contract and battle throughout the area automatically.
 *  Users can collect their experience and rewards whenever they please, and characters can be removed at any time.
 *  When a character is added to the area contract, a receipt token is minted to the transaction caller that represents their character.
 *  This receipt token is later used to reclaim the character which was placed inside of this contract and then that token is  burned.
 *
 *  Area contracts are range from easy to extremely difficult. It's recommended that you do battle in a contract which suits your characters skill level
 *  to optimize rewards and experience.
 *
 */
contract Area is ERC721Enumerable, ERC721Holder, Operator, IArea {

    address public characters;
    address public gems;
    
    uint256 public difficulty;
    uint256 public index;
    uint256 public expRate = uint256(50 ether) / uint256(86400);
    uint256 public dropRate = uint256(20 ether) / uint256(86400);

    mapping (uint256 => uint256) lastTimeUpdated;
    mapping (uint256 => uint256) successRate;

    constructor(
        address _characters, 
        address _gems,
        uint256 _difficulty
    ) ERC721("Emerald Forest", "Area-1") {
        characters = _characters;
        gems = _gems;
        difficulty = _difficulty;
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

    function getSuccessRate(uint256 characterID) external view returns (uint256) {
        return successRate[characterID];
    }

    function getExpPerHour(uint256 characterID) external view returns (uint256) {
        uint expPerHour = ((expRate * successRate[characterID]) / 1e18) * 3600;

        return expPerHour;
    }

    function getGoldPerHour(uint256 characterID) external view returns (uint256) {
        uint dropPerHour =  ((dropRate * successRate[characterID]) * 3600);
        return dropPerHour;
    }

    function getAvailableExp(uint256 characterID) external view returns (uint256) {
        uint256 lastUpdated = lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        uint experience = (timeBattling * expRate * successRate[characterID]) / 1e18;

        return experience;
    }

    function getAvailableGold(uint256 characterID) external view returns (uint256) {
        uint256 lastUpdated = lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        uint256 gold = timeBattling * dropRate * successRate[characterID];

        return gold;
    }

    function enter(uint256 characterID) public {
        IERC721(characters).transferFrom(msg.sender, address(this), characterID);

        // Assigns the characterID to the newly minted token.
        // This saves gas setting IDs while also making it a lot easier to understand which token it represents.
        _mint(msg.sender, characterID);

        _setAreaSuccessRate(characterID);

        lastTimeUpdated[characterID] = block.timestamp;

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
    function exit(uint256 characterID) public {
        _burn(characterID);
        IERC721(characters).transferFrom(address(this), msg.sender, characterID);
        lastTimeUpdated[characterID] = block.timestamp;
    }


    function testAreaSuccess(uint256 characterID) public view returns (uint256 power, uint256 success) {
        Character memory character = ICharacters(characters).getCharacter(characterID);

        power = sqrt(character.hp * character.str * character.dex * character.agi * character.def);

        success = power * 1e18 / difficulty;
    }
    /**
     *
     *  @dev Calculates the success rate that a character will have for each battle they engage in while in this area.
     *  This is used to calculate the reward rate for a character.
     *
     *  @param characterID - CharacterID
     *
     */
    function _setAreaSuccessRate(uint256 characterID) public {
        Character memory character = ICharacters(characters).getCharacter(characterID);

        uint256 power = sqrt(character.hp * character.str * character.dex * character.agi * character.def);

        uint256 successPercentile = power * 1e18 / difficulty;
        
        if (successPercentile < 750_000_000_000_000_000) {
            successRate[characterID] = 0;
        } else if (successPercentile > 1e18) {
            successRate[characterID] = 1e18;
        }
    }

    /**
     */
    function refresh(uint256 id) public {

    }

    /**
     *  Gets the currently set variables for a character based on their success rate in an area.
     */
    function testRates(uint256 characterID) public view returns (uint256, uint256) {
        uint256 lastUpdated = lastTimeUpdated[characterID];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * expRate * successRate[characterID]) / 1e18);

        uint256 drop = timeBattling * dropRate * successRate[characterID];

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
    function _getExperienceAndDrops(uint256 characterID) internal {
        uint256 lastUpdated = lastTimeUpdated[characterID];
        uint256 timeBattling = block.timestamp - lastUpdated;
        uint32 experienceGained = uint32((timeBattling * expRate * successRate[characterID]) / 1e18);
        uint256 goldGained = timeBattling * dropRate * successRate[characterID];

        /// Assign exp to character
        ICharacters(characters).gainExperience(characterID, experienceGained);

        /// Mint gold to character owner.
        IGems(gems).mintTo(msg.sender, goldGained);

        /// Update characters last update time. This ensures they don't claim additional rewards.
        lastTimeUpdated[characterID] = block.timestamp;

        /// Resets their success rate incase they have leveled up.
        _setAreaSuccessRate(characterID);

        emit ExperienceAndGoldGained(characterID, experienceGained, goldGained);
    }

    /**
     *
     *  @dev Collects rewards based on time spent in the area.
     *
     */
    function collect(uint256 id) public {
        if (ownerOf(id) != msg.sender) revert NotOwner();
        _getExperienceAndDrops(id);
    }

    /**
     *
     *  @dev Characters who are in this area generate experience automatically over time. Experience can be claimed here, or automatically upon exiting the area.
     *  If you are in this area for an extended period of time, it can be useful to claim experience before you leave, so that you are able to level up.
     *  
     *  @param characterID - The characterID which is claiming this experience.
     *
     */
    function collectExperience(uint256 characterID) public {
        if (ownerOf(characterID) != msg.sender) revert NotOwner();

        uint256 lastUpdated = lastTimeUpdated[characterID];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * expRate * successRate[characterID]) / 1e18);

        ICharacters(characters).gainExperience(characterID, experience);

        lastTimeUpdated[characterID] = block.timestamp;
    }
}