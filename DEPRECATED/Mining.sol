// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/ITradeskillToken.sol";
import "./access/Operator.sol";
import "./interfaces/ITradeskill.sol";

contract Mining is ERC721, IERC721Receiver, ERC721Holder, ITradeskill {
    
    address characters;
    ITradeskillToken ore;

    mapping (uint256 => address) owners;
    mapping (uint256 => uint256) lastTimeUpdated;

    uint256 baseSpeed = 10e18;

    error NotOwner();

    constructor(address _ore, address _characters) ERC721("Lunarium", "Lunarium") {
        characters = _characters;
        ore = ITradeskillToken(_ore);
    }

    //// One stamina = 10 seconds

    function getHourlyExperience(uint256 cid) external view override returns (uint256) {
        Character memory character = ICharacters(characters).getCharacter(cid);
        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return 1e17 * actionsPerHour;
    }

    function getHourlyMaterials(uint256 cid) external view override returns (uint256) {
        Character memory character = ICharacters(characters).getCharacter(cid);
        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 actionsPerHour = 3600e18 / characterSpeed;

        return (((character.level/5) + 1) * actionsPerHour) * 1e18;
    }

    function getAvailableExperience(uint256 cid) public view override returns (uint256 experienceGained) {
        (experienceGained,) = getAvailableExpAndMaterials(cid);
    }

    function getAvailableMaterials(uint256 cid) public view override returns (uint256 materialsGained) {
        (,materialsGained) = getAvailableExpAndMaterials(cid);
    }

    function getAvailableExpAndMaterials(uint256 cid) public view override returns (uint256 expGained, uint256 materialsGained) {
        Character memory character = ICharacters(characters).getCharacter(cid);

        uint lastUpdate = lastTimeUpdated[cid];

        uint256 characterSpeed = baseSpeed - (baseSpeed * (character.multipliers.speed - 1e18) / 1e18);

        uint256 timeSinceLast = character.stamina * 10  > block.timestamp - lastUpdate ? block.timestamp - lastUpdate : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        expGained  = actionsSinceLast * 1e17;
        materialsGained = (((character.level/5) + 1) * actionsSinceLast) * 1e18;
    }

    function collect(uint256 characterId) override external {   
        if (owners[characterId] != _msgSender()) revert NotOwner();
        Character memory character = ICharacters(characters).getCharacter(characterId);

        // Calculates character mining speed based on their multipliers.
        uint256 characterSpeed = (baseSpeed - ((baseSpeed * character.multipliers.speed) / 1e18) / 2);
        /// Calculates the effective time since last claim; If the users effective stamina time is greater than the actual time, the actual time is used.
        /// If the stamina is less than, the stamina is used. This is to limit based on stamina amounts,
        uint256 timeSinceLast = character.stamina * 10  > block.timestamp - lastTimeUpdated[characterId] ? block.timestamp - lastTimeUpdated[characterId] : character.stamina * 10;

        uint256 actionsSinceLast = timeSinceLast * 1e18 / characterSpeed;

        /// Assuming an average block length of ~1-2 seconds
        uint256 totalMined = (((character.level/5) + 1) * actionsSinceLast) * 1e18;

        uint experienceGained = actionsSinceLast * 1e17;

        ore.mintTo(_msgSender(), totalMined);

        ICharacters(characters).gainTradeExperience(character.id, 0, experienceGained );

        lastTimeUpdated[characterId] = block.timestamp;
    }

    function start(uint256 cid) external override {
        IERC721(characters).transferFrom(_msgSender(), address(this), cid);

        owners[cid] = _msgSender();

        lastTimeUpdated[cid] = block.timestamp;

        _mint(msg.sender, cid);

        //emit TradeskillActive(0, cid);
    }

    function stop(uint256 cid) external override {
        if (owners[cid] != _msgSender()) revert();

        _burn(cid);
        
        IERC721(characters).transferFrom(address(this), _msgSender(), cid);

        delete owners[cid];

        //emit TradeskillInactive(0, cid);
    }
}