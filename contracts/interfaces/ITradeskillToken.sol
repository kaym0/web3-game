// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITradeskillToken {
    function mintTo(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}