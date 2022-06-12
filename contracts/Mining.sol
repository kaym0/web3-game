// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/ICharacters.sol";
import "./interfaces/ITradeskillToken.sol";
import "./access/Operator.sol";

contract Mining is ERC721, IERC721Receiver, ERC721Holder {
    
    address characters;
    address ore;

    mapping (uint256 => address) owners;
    mapping (uint256 => uint256) lastBlockUpdated;

    event BegunMining(uint256 characterId);
    event StoppedMining(uint256 characterId);

    error NotOwner();

    constructor() ERC721("Lunarium", "Lunarium") {

    }

    function collect(uint256 characterId) external {   
        if (owners[characterId] != _msgSender()) revert NotOwner();
        Character memory character = ICharacters(characters).getCharacter(characterId);

        uint256 timeSinceLast = block.number - lastBlockUpdated[characterId];

        /// Assuming an average block length of ~1-2 seconds
        uint256 totalMined = character.level * 1e18 * 50 * timeSinceLast / 43200;

        ITradeskillToken(ore).mintTo(_msgSender(), totalMined);

        lastBlockUpdated[characterId] = block.number;
    }

    function mine(uint256 characterId) external {
        IERC721(characters).transferFrom(_msgSender(), address(this), characterId);

        owners[characterId] = _msgSender();

        lastBlockUpdated[characterId] = block.number;

        emit BegunMining(characterId);
    }

    function stop(uint256 characterId) external {
        if (owners[characterId] != _msgSender()) revert();

        IERC721(characters).transferFrom(address(this), _msgSender(), characterId);

        delete owners[characterId];
    }
}