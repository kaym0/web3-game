// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGems is IERC20 {
    function mintTo(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function buyTokens() external payable;
}