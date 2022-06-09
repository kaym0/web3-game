// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum JewelType {
    SWIFTNESS,
    POWER,
    RICHES  
}

struct Jewel {
    JewelType prototype;
    bool equipped;
}

interface IJewel {
    event EquipmentCreated(address indexed owner, uint256 indexed id);
    event EquipmentBurned(address indexed owner, uint256 indexed id);
    event ItemEquipped(address indexed owner, uint256 indexed id);
    event ItemRemoved(address indexed owner, uint256 indexed id);

    error NotOwner();
    error EquipmentInUse();

    function ownerOf(uint256 id) external view returns (address);
    function setEquipped(uint256 id, bool isEquipped) external;
    function getJewel(uint256 id) external view returns (Jewel memory);
    function createEquipment(address to, string memory name, uint32[] memory values) external;
    function burn(uint256 id) external;
}
