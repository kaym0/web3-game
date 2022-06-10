// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IEquipment, Equip } from "../interfaces/IEquipment.sol";
import { Character } from "../interfaces/ICharacters.sol";

struct CharacterStorage {

    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////// ERC721A.sol
    uint256 BITMASK_ADDRESS_DATA_ENTRY;
    // The bit position of `numberMinted` in packed address data.
    uint256 BITPOS_NUMBER_MINTED;

    // The bit position of `numberBurned` in packed address data.
    uint256 BITPOS_NUMBER_BURNED;

    // The bit position of `aux` in packed address data.
    uint256 BITPOS_AUX;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 BITMASK_AUX_COMPLEMENT;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 BITPOS_START_TIMESTAMP;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 BITMASK_BURNED;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 BITPOS_NEXT_INITIALIZED;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 BITMASK_NEXT_INITIALIZED;

    // The tokenId of the next token to be minted.
    uint256 _currentIndex;

    // The number of tokens burned.
    uint256 _burnCounter;

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    mapping(uint256 => uint256) _packedOwnerships;


    mapping(address => uint256) _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;


    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //// Operator.sol


    address masterOperator;
    bool operatorsCanWrite;
    mapping (address => bool) operators;
    uint8 permissions;


    int128 MIN_64x64;
    int128 MAX_64x64;


    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //// Character.sol
    bool initialized;
    uint256 price;
    uint256 index;

    IEquipment equipment;

    uint32 firstMintedOfLastBlock;
    uint32 currentBlockTokenIndex;
    uint32 lastMintedBlock;
    
    mapping (uint256 => Character) characters;
    mapping (uint256 => mapping(uint256 => Equip)) characterEquipment;

/*
    /// Core ERC20 variables
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    mapping(address => uint256) approvedContractIndexes;
    address[] approvedContracts;
    bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint256 totalSupply;

    /// $pace token variables
    mapping (address => bool) excludedFromTax;
    address treasury;
    address communityWallet;
    address tokenDisperser;
    uint256 taxPercentage;
    uint256 taxCount;
    bool burnOnTransfer;
*/
}
