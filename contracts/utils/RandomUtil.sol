// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;

    function randomSeededMinMax(uint min, uint max, bytes1 seed) internal pure returns (uint32) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint random = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        random = random.add(min);
        return uint32(random);
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, bytes1 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function plusMinus30PercentSeeded(uint256 num, bytes1 seed) internal pure returns (uint256) {
        // avoid decimal loss
        uint256 thirtyPercent = num.mul(30).div(100);
        return num.sub(thirtyPercent).add(randomSeededMinMax(0, thirtyPercent.mul(2), seed));
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}