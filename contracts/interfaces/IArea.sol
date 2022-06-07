// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IArea {
    event AreaEntered(address indexed owner, uint256 characterID);
    event AreaLeft(address indexed owner, uint256 characterID);

    error NotOwner();

    function enter(uint256 id) external;
    function exit(uint256 id) external;
    function collect(uint256 id) external;
    function characters() external view returns (address);
    function coin() external view returns (address);
    function index() external view returns (uint256);
    function expRate() external view returns (uint256);
    function dropRate() external view returns (uint256);
}