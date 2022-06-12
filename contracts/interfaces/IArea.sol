// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IArea {

    event AreaCreated(uint256 areaID);
    event AreaEntered(address indexed owner, uint256 characterID);
    event AreaLeft(address indexed owner, uint256 characterID);
    event ExperienceAndGoldGained(uint256 indexed characterID, uint256 exp, uint256 gold);

    error NotOwner();

    //function enter(uint256 areaID, uint256 characterID) external;
    //function exit(uint256 areaID, uint256 characterID) external;
    //function collect(uint256 areaID, uint256 characterID) external;


    //function characters() external view returns (address);
    //function gems() external view returns (address);
    //function index() external view returns (uint256);
    //function expRate() external view returns (uint256);
    //function dropRate() external view returns (uint256);
}