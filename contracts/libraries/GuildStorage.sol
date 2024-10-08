// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";
import { IEquipment, Equip } from "../interfaces/IEquipment.sol";
import {IGems} from "../interfaces/IGems.sol";
import { Character, CharacterSeed, ICharacters } from "../interfaces/ICharacters.sol";


struct GuildBoosts {
    uint64 experience;
    uint64 lunarium;
    uint64 drops;
    uint64 speed;
}

struct AppStorage {
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
    //// GuildFacet.sol
    IGems gems;

    uint256 guildID;
    uint256 levelRequirement;
    uint256 size;

    bool initialized;
    bool hasLevelRequirement;
    bool requiresInvite;

    address characters;

    //mapping (address => uint256) public members;
    mapping (uint256 => bool) invites;
    mapping (uint256 => uint256) joinDate;

    uint256[] boosts;

}

contract Modifiers {

}
