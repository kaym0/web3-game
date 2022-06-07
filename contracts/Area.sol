// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./access/Operator.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/ICoin.sol";
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
 *  This receipt token is later used to reclaim the character which was placed inside of this contract and then burned.
 *
 */
contract Area is ERC721, ERC721Holder, Operator, IArea {

    address public characters;
    address public coin;

    uint256 public index;
    uint256 public expRate = uint256(500 ether) / uint256(86400);
    uint256 public dropRate = uint256(100 ether) / uint256(86400);

    mapping (uint256 => uint256) lastTimeUpdated;
    mapping (uint256 => uint256) successRate;

    constructor(address _characters, address _coin) ERC721("Emerald Forest", "Area-1") {
        characters = _characters;
        coin = _coin;
    }

    function population() public view returns (uint256) {
        return IERC721(characters).balanceOf(address(this));
    }

    function enter(uint256 id) public {
        IERC721(characters).transferFrom(msg.sender, address(this), id);

        // Assigns the characterID to the newly minted token.
        // This saves gas setting IDs while also making it a lot easier to understand which token it represents.
        _mint(msg.sender, id);

        lastTimeUpdated[id] = block.timestamp;

        emit AreaEntered(msg.sender, id);
    }

    /**
     *
     *  @dev Exits the area. This removes the character from the contract and burns the token which represents them here as a receipt.
     *  
     *  @notice A receipt token is required to withdraw a character from this contract.
     *
     *  @param id - The ID of the token to withdraw. This is the same tokenID as the token which is used to claim it.
     *
     */
    function exit(uint256 id) public {
        _burn(id);
        IERC721(characters).transferFrom(address(this), msg.sender, id);
        lastTimeUpdated[id] = block.timestamp;
    }

    /**
     *
     *  @dev Calculates the success rate that a character will have for each battle they engage in while in this area.
     *  This is used to calculate the reward rate for a character.
     *
     *  @param id - CharacterID
     *
     */
    function _successRate(uint256 id) public {
        Character memory character = ICharacters(characters).getCharacter(id);

        successRate[id] = 100e18;
    }

    /**
     */
    function refresh(uint256 id) public {

    }

    /**
     *
     *  @dev Handles distribution of experience and loot to character.
     *
     *  @param id - The characterID to give loot and experience to.
     *
     *
     */
    function _getExperienceAndDrops(uint256 id) internal {
        uint256 lastUpdated = lastTimeUpdated[id];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * expRate * successRate[id]) / 100e18);

        uint256 drop = timeBattling * dropRate * successRate[id] / 100e18;

        ICharacters(characters).gainExperience(id, experience);

        ICoin(coin).mintTo(msg.sender, drop);

        lastTimeUpdated[id] = block.timestamp;
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
     *  @param id - The characterID which is claiming this experience.
     *
     */
    function collectExperience(uint256 id) public {
        if (ownerOf(id) != msg.sender) revert NotOwner();

        uint256 lastUpdated = lastTimeUpdated[id];

        uint256 timeBattling = block.timestamp - lastUpdated;

        uint32 experience = uint32((timeBattling * expRate * successRate[id]) / 100e18);

        ICharacters(characters).gainExperience(id, experience);

        lastTimeUpdated[id] = block.timestamp;
    }
}