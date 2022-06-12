// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { CharacterStorage } from "./libraries/CharacterStorage.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

/**
 *  @title $pace Token Contract
 *  @author kaymo.eth
 *  $Pace Token, a cross-chain token serving as the backbone of OneSpace metaverse platform 
 */
contract CharacterDiamond {
    CharacterStorage state;

    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory functionSelectors = new bytes4[](1);

        functionSelectors[0] = IDiamondCut.diamondCut.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
        LibDiamond.setContractOwner(_contractOwner);



        state.BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

        // The bit position of `numberMinted` in packed address data.
        state.BITPOS_NUMBER_MINTED = 64;

        // The bit position of `numberBurned` in packed address data.
        state.BITPOS_NUMBER_BURNED = 128;

        // The bit position of `aux` in packed address data.
        state.BITPOS_AUX = 192;

        // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
        state.BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

        // The bit position of `startTimestamp` in packed ownership.
        state.BITPOS_START_TIMESTAMP = 160;

        // The bit mask of the `burned` bit in packed ownership.
        state.BITMASK_BURNED = 1 << 224;

        // The bit position of the `nextInitialized` bit in packed ownership.
        state.BITPOS_NEXT_INITIALIZED = 225;

        // The bit mask of the `nextInitialized` bit in packed ownership.
        state.BITMASK_NEXT_INITIALIZED = 1 << 225;

        /// Operator vars.
        state.masterOperator = _contractOwner;
        state.operatorsCanWrite = false;
        state.permissions = 0;


        /// ABDK vars.
        state.MIN_64x64 = -0x80000000000000000000000000000000;
        state.MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      

        state.masterOperator = msg.sender;
        state.operators[msg.sender] = true;

        state.price = 0.0001 ether;
    }
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
             // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
