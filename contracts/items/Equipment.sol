// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../token/ERC721/ERC721A.sol";
import "../token/ERC721/extensions/ERC721AQueryable.sol";
import "../interfaces/IEquipment.sol";
import "../access/Operator.sol";

/***
 *
 *  @title Equipment
 *
 *  @version 0.0.1
 *
 *  @author kaymo.eth
 *
 *  @dev Equipment currently does not have an image associated with it, and returned data is strictly stat based.
 *
 *  An ERC721 implementation which stores equipment stats as NFTs, allowing them to be minted and owned. Equipment is a utility NFT which
 *  is equipable to Characters, improving their strength and combat capabilities. This contract uses the operator contract to allow the primary
 *  game contract to mint equipment to addresses as they earn, buy, or find equipment in-game.
 *
 */
 
contract Equipment is ERC721AQueryable, Operator, IEquipment {

    uint32 index;

    mapping (uint256 => Equip) public equipment;

    constructor() ERC721A("Equips","Equipment") {}

    function setEquipped(uint256 id, bool isEquipped) public {
        Equip storage equip = equipment[id];

        if (ownerOf(id) != msg.sender) revert NotOwner();

        equip.equipped = isEquipped;
    }

    function ownerOf(uint256 id) public view override(ERC721A, IERC721A, IEquipment) returns (address) {
        return super.ownerOf(id);
    }

    /**
     *
     *  @dev _transfer override. This checks if the equipment is in use before transferring. Equipment that is currently being used is
     *  not transferrable and will cause this transaction to revert. To transfer your equipment, you must first unequip it.
     *
     *  @param from - The address the token is being transferred from.
     *
     *  @param to - The recepient address for the token
     *
     *  @param tokenId - The equipmentID for the token being transferred.
     *
     */
    function _transfer( address from, address to, uint256 tokenId) internal virtual override {
        if (equipment[tokenId].equipped) revert EquipmentInUse();
        super._transfer(from, to, tokenId);
    }

    /**
     *
     *  @dev _burn override. This checks if the equipment is in use before burning. Equipment that is currently being used is
     *  not transferrable and not burnable and will cause this transaction to revert. To transfer or burn your equipment, you must first unequip it.
     *
     *  @param tokenId - The equipmentID for the token being burnned.
     *
     */
    function _burn(uint256 tokenId)  internal virtual override {
        if (equipment[tokenId].equipped) revert EquipmentInUse();
        super._burn(tokenId);
    }

    /**
     *
     *  @dev Fetches an equipment by ID.
     *
     *  @param id - equipemntID
     *
     *  @return Equipment
     *
     */
    function getEquipment(uint256 id) public view returns (Equip memory) {
        return equipment[id];
    }

    function getEquipmentOfOwner(address owner) public view returns (Equip[] memory) {
        uint256[] memory tokens = tokensOfOwner(owner);
        Equip[] memory equips = new Equip[](tokens.length);

        for (uint i; i < tokens.length; i++) {
            equips[i] = equipment[tokens[i]];
        }

        return equips;
    }

    /**
     *
     *  @dev Mints a new piece of equipment to a specific address.
     *
     *  @notice This function is a game-mechanic and only accessible to the game contracts.
     *
     *  @param to - The address receiving equipment
     *
     *  @param name - The name of the equipment
     *
     *  @param values - An array of stats that are allocated to the equipment piece.
     *
     */
    function createEquipment(address to, string memory name, uint32[] memory values) public onlyOperator {
        _mint(to, 1);

        equipment[index] = Equip(name, index, values[0], values[1], values[2], values[3], values[4], values[5], false);

        emit EquipmentCreated(to, index);

        index = index + 1;
    }

    /**
     *
     *  @dev Burns a piece of equipment and deletes all data associated with it.
     *
     *  @notice The token must be owned by the caller of the function in order to burn it.
     *
     *  @param id - The EquipmentID of the equipment to burn.
     *
     */
    function burn(uint256 id) public {
        if (ownerOf(id) != msg.sender) revert NotOwner();

        _burn(id);

        delete equipment[id];

        emit EquipmentBurned(msg.sender, id);
    }
}