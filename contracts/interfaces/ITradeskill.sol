// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITradeskill {
    function getHourlyExperience(uint256 cid) external view returns (uint256);
    function getHourlyMaterials(uint256 cid ) external view returns (uint256);
    function getAvailableExperience(uint256 cid) external view returns (uint256 experienceGained);
    function getAvailableMaterials(uint256 cid) external view returns (uint256 materialsGained);
    function getAvailableExpAndMaterials(uint256 cid) external view returns (uint256 expGained, uint256 materialsGained);
    function collect(uint256 characterId) external;
    function stop(uint256 characterId) external;
    function start(uint256 skillId, uint256 characterId) external;
}