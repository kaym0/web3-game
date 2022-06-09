// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { CharacterStorage } from "./CharacterStorage.sol";

library LibAppStorage {
    function diamondStorage() internal pure returns (CharacterStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}