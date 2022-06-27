// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import  "./libraries/LibDiamond.sol";
import  "./interfaces/IDiamondCut.sol";
import  "./interfaces/IDiamondLoupe.sol";
import  "./interfaces/IERC165.sol";
import  "./interfaces/IERC173.sol";

contract InitDiamond {
    bytes32 constant STRUCT_POS = keccak256("$pace.diamond.storage");
    PaceStorage internal s;

    struct PaceStorage {
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => uint256) balances;
        address[] approvedContracts;
        mapping(address => uint256) approvedContractIndexes;
        bytes32[1000] emptyMapSlots;
        address contractOwner;
        uint256 totalSupply;

        mapping (address => bool) excludedFromTax;
        address treasury;
        address communityWallet;
        address tokenDisperser;
        uint256 taxPercentage;
        uint256 taxCount;
        bool burnOnTransfer;
    }
    
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }
}