// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IArea {

    event AreaCreated(uint256 areaID);
    event AreaEntered(address indexed owner, uint256 characterID);
    event AreaLeft(address indexed owner, uint256 characterID);
    event ExperienceAndGemsGained(uint256 indexed characterID, uint256 exp, uint256 gold);

    error NotOwner();
}