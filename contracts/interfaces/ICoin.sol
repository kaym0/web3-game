// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICoin {
    function mintTo(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}