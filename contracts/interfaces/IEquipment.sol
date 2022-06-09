// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


struct Equip {
    string name;
    uint256 id;
    uint32 hp;
    uint32 str;
    uint32 dex;
    uint32 def;
    uint32 agi;
    uint32 slot;
    bool equipped;
}

interface IEquipment {
    event EquipmentCreated(address indexed owner, uint256 indexed id);
    event EquipmentBurned(address indexed owner, uint256 indexed id);
    event ItemEquipped(address indexed owner, uint256 indexed id);
    event ItemRemoved(address indexed owner, uint256 indexed id);

    error NotOwner();
    error EquipmentInUse();

    function ownerOf(uint256 id) external view returns (address);
    function setEquipped(uint256 id, bool isEquipped) external;
    function getEquipment(uint256 id) external view returns (Equip memory);
    function createEquipment(address to, string memory name, uint32[] memory values) external;
    function burn(uint256 id) external;
}
