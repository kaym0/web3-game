// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/IGems.sol";

 struct Guild {
    string name;
    address owner;
    uint256 guildId;
    uint256 levelRequirement;
    uint256 size;

    bool hasLevelRequirement;
    bool requiresInvite;

    GuildBoosts boosts;
}

struct GuildBoosts {
    uint64 experience;
    uint64 lunarium;
    uint64 drops;
    uint64 speed;
}

contract GuildFactory is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    uint256 guildCostGems = 100000 ether;
    uint256 guildCostLunarium = 100 ether;
    /**
     * Character contract
     */
    address characters;

    /**
     * Related In-Game Tokens, used for purchasing a guild and upgrading.
     */
    address gems;
    address lunarium;


    /**
     * Trade skill tokens. These are used for upgrading guilds!
     */
    address ore;
    address fish;
    address wood;
    address stone;

    uint256 public guildIndex;

    mapping(uint256 => Guild) public guilds;
    mapping(uint256 => mapping(uint256 => bool)) invites;
    mapping(uint256 => mapping(uint256 => uint256)) joinDate;


   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Guild", "GUILD");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    event MemberJoined(address indexed owner, uint256 indexed characterID);
    event MemberLeft(address indexed owner, uint256 indexed characterID);
    event Donation(address indexed owner, uint256 indexed donation);
    event BankWithdrawl(address indexed owner, uint256 indexed withdrawal);

    error Initialized();
    error NotCharacterOwner();
    error NotInvited();
    error LevelRequirementNotMet();
    error NotMember();
    
    function createGuild(string memory name) external {
        guildIndex = guildIndex + 1;
        
        guilds[guildIndex] = Guild(
            name,
            _msgSender(),
            guildIndex,
            0,
            10,
            false,
            false,
            GuildBoosts(
                1e18,
                1e18,
                1e18,
                1e18
            )
        );
    }


    /**
     *  
     *  @dev Has a character join the guild.
     *
     *  Requirements:
     *  - Caller must own the character joining.
     *  - If requireInvite is enabled, the character must own an invite.
     *  - If there is a level requirement, the level requirement must be met.
     *
     */
    function joinGuild(uint256 characterID) external {
        Character memory character = ICharacters(characters).getCharacter(characterID);

        if (character.owner != msg.sender) revert NotCharacterOwner();
        if (requiresInvite == true && invites[characterID] == false) revert NotInvited();
        if (hasLevelRequirement) {
            try ICharacters(characters).getCharacter(characterID) returns (Character memory char) {
                if (char.level < levelRequirement) revert LevelRequirementNotMet();
            } catch {
                revert();
            }
        }

        /// Mint the guild membership as the same tokenID as the character itself.
        _mint(msg.sender, characterID);

        joinDate[characterID] = block.timestamp;

        emit MemberJoined(msg.sender, characterID);
    }

    /**
     *
     *  @dev Leaves guild
     *
     *  Requirements:
     *  - Character must be owned by the caller.
     *  - The guild membership for this character must be owned by the caller & approved for this contract.
     *
     *  @param characterID - The characterID which is leaving the guild.
     *
     */
    function leaveGuild(uint256 characterID) external {
        Character memory character = ICharacters(characters).getCharacter(characterID);

        if (character.owner != msg.sender) revert NotCharacterOwner();

        _burn(characterID);

        emit MemberLeft(msg.sender, characterID);
    }

    /**
     *
     *  @dev Kicks a member from the guild. 
     *
     *  Requirements:
     *  - Caller must be owner or operator of the contract.
     *  
     *  @param characterID - The ID of the character to kick.
     *
     */
    function kickMember(uint256 characterID) external onlyOwner {
        _burn(characterID);

        emit MemberLeft(msg.sender, characterID);
    }

    /**
     *
     *  @dev Invite a character to the guild. This is only required if the guild requires an invite to join.
     *
     *  Requirements:
     *  - Caller must be owner or operator.
     *
     */
    function inviteCharacter(uint256 characterID) external {
        if (balanceOf(msg.sender) == 0) revert NotMember();
        invites[characterID] = true;
    }

    /**
     *
     *  @dev Fetches all boosts which are currently activate within the guild.
     *  
     *  @return boosts - Boosts 
     *
     */
    function getBoosts() external view returns (uint256[] memory) {
        return boosts;
    }

    function getBoostUpgradeCost(uint256 currentLevel) public pure returns (uint256) {
        return currentLevel**5 + 20000;
    }

    function donate(uint256 donation) external {
        gems.transferFrom(msg.sender, address(this), donation);

        emit Donation(msg.sender, donation);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        gems.transfer(msg.sender, amount);

        emit BankWithdrawl(msg.sender, amount);
    }
    
    /**
     *
     *  @dev Upgrades a specific boost for a price paid in gems. The currency is spent from the guild wallet.
     *
     *  @param boostID - The IDs are as follows:
     *  1: experience
     *  2: lunarite
     *  3: drops
     *  4: speed
     *
     */
    function upgradeBoost(uint256 boostID) external {
        uint256 currentLevel = boosts[boostID];
        uint256 upgradeCost = getBoostUpgradeCost(currentLevel);

        require(gems.balanceOf(address(this)) >= upgradeCost, "Insufficient Gems") ;

        gems.burnFrom(address(this), upgradeCost);
        boosts[boostID] = boosts[boostID] + 1;
    }
}