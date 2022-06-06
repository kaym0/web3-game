// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { Equipment } from "./IEquipment.sol";

struct Character {
    uint32 level;
    uint32 exp;
    uint32 hp;
    uint32 str;
    uint32 def;
    uint32 dex;
    uint32 agi;
}

interface ICharacters {
    event CharacterCreated(address indexed owner, uint256 indexed id);
    event CharacterBurned(address indexed owner, uint256 indexed id);

    error InsufficientAmount();
    error NotOwner();
    error AlreadyEquipped();
    error NotOwnerOfEquipment();

    function price() external view returns (uint256);
    function index() external view returns (uint256);
    function gainExperience(uint256 id, uint32 amount) external;
    //function getCharactersOfOwner(address owner) external view returns (Character[] memory c);
    function getCharacter(uint256 id) external view returns (Character memory);
    //function mintCharacter(uint256 seed) external payable;
    function burnCharacter(uint256 id) external;
}
