// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IGems.sol";
import "./interfaces/IEquipment.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./token/ERC721/extensions/IERC721AQueryable.sol";
import "./access/Operator.sol";


/***
 *
 *  @title Marketplace
 *
 *  @author kaymo.eth
 *
 *  @custom:experimental
 *
 *  @version 0.0.2
 *
 *  A marketplace where players can buy and sell their equipment and items for currency. 
 *
 *  This is an early-strage contract which is currently experimental and being built with the intention of further development. 
 *
 */
contract Marketplace is Operator {

    uint256 lastMaterialId;
    uint256 public fee = 250; // 2.5%
    address public equipment;
    address public gems;

    mapping (uint256 => MaterialListing[]) private               _materialListings;
    mapping (uint256 => mapping(uint256 => uint256)) private     _materialIndex;
    mapping (uint256 => Listing) public                         listings;
    mapping (uint256 => address) public                         materialContracts;

    constructor(address _equipment, address _gems) {
        equipment = _equipment;
        gems = _gems;
    }

    struct MaterialListing {
        uint256 id;
        address owner;
        uint256 itemId;
        uint256 amount;
        uint256 price;
    }

    struct Listing {
        address owner;
        uint256 id;
        uint256 price;
    }

    event NewListing            (uint256 indexed tokenId, address indexed owner, uint256 indexed price);
    event ItemSold              (uint256 indexed tokenId, address indexed buyer, uint256 indexed price);
    event ListingRemoved        (uint256 indexed tokenId, address indexed owner);

    error InsufficientPayment();
    error ItemDoesNotExist();
    error NotOwner();



    function totalMaterialListings(uint256 materialId) public view returns (uint256) {
        return _materialListings[materialId].length;
    }


    function allMaterialListings(uint256 materialId) external view returns (MaterialListing[] memory) {
        return _materialListings[materialId];
    }

    function materialListingFromRange(uint256 materialId, uint256 indexA, uint256 indexB) external view returns (MaterialListing[] memory) {
        if (indexB < indexA) {
            return _materialListings[materialId];
        }

        MaterialListing[] memory allListings = _materialListings[materialId];
        MaterialListing[] memory returnListings = new MaterialListing[](5);


        for (uint i = 0; i < returnListings.length; i++) {
            returnListings[i] = allListings[i + indexA];
        }

        return returnListings;
    }

    function addMaterialId(uint256 materialId, address materialAddress) external onlyOperator {
        materialContracts[materialId] = materialAddress;
    }
    /**
     *
     *  @dev Retrieves all listings currently available. This function is gas-heavy and will likely fail if the marketplace becomes widely used,
     *  future implementations will find better methods to accomplish this.
     *
     */
    function getListings() public view returns (Listing[] memory) {
        uint256[] memory saleIDs = IERC721AQueryable(equipment).tokensOfOwner(address(this));

        return _getListingsFromIds(saleIDs);
    }

    /**
     *
     *  @dev Gets all listings and stores them in an array
     *
     */
    function _getListingsFromIds(uint256[] memory tokenIds) internal view returns (Listing[] memory) {
        Listing[] memory list = new Listing[](tokenIds.length);

        for (uint i; i < tokenIds.length; i++) {
            list[i] = listings[tokenIds[i]];
        }

        return list;
    }

    /**
     *  
     *  @dev Lists trade skill materials on the market for sale.
     *  
     */
    function addMaterialListing(uint256 materialId, uint256 price, uint256 amount) external {
        IERC20(materialContracts[materialId]).transferFrom(msg.sender, address(this), amount);

        _addMaterialListing(materialId, MaterialListing(lastMaterialId, msg.sender, materialId, amount, price));
    }

    function removeMaterialListing(uint256 materialId, uint256 listingId) external {
        MaterialListing storage listing = _materialListings[materialId][listingId];

        IERC20(materialContracts[listing.itemId]).transfer(msg.sender, listing.amount);

        _removeMaterialListing(materialId, listingId);
    }


     function buyMaterial(uint256 materialId, uint256 listingId) external {
        MaterialListing storage listing = _materialListings[materialId][listingId];

        /// ERC20 will fail if the user does not have sufficient funds.
        IERC20(gems).transferFrom(msg.sender, address(this), listing.price);
        /// Transfer gems to owner of listing, sub fee.
        IERC20(gems).transfer(listing.owner, listing.price * (10000 - fee) / 10000);
        /// Transfer resources to the purchaser.
        IERC20(materialContracts[materialId]).transfer(msg.sender, listing.amount);

        _removeMaterialListing(materialId, listingId);
     }

    /**
     *
     *  @dev Adds equipment to the marketplace. This requires an approval by the user that will allow this contract to move their item.
     *  
     *  @param id - The equipmentID
     *
     *  @param price - The price as WEI that is being requested for the item being listed.
     *
     */
    function listEquipment(uint256 id, uint256 price) external {
        IERC721AQueryable(equipment).transferFrom(msg.sender, address(this), id);

        listings[id] = Listing(msg.sender, id, price);

        emit NewListing(id, msg.sender, price);
    }

    /**
     *
     *  @dev Executes a purchase for a specific item. The correct amount of currency must be sent with this transaction, else it fails.
     *
     *  @param id - The equipmentID of the token to purchase.
     *
     */
    function buyEquipment(uint256 id) public payable {
        Listing storage listing = listings[id];

        if (msg.value < listing.price) revert InsufficientPayment();
        if (listing.owner == address(0)) revert ItemDoesNotExist();

        IERC721A(equipment).transferFrom(address(this), msg.sender, id);

        payable(listing.owner).transfer(listing.price * (10000 - fee)  / 10000);

        delete listings[id];

        emit ItemSold(id, msg.sender, listing.price);
    }

    /**
     *
     *  @dev Removes a listing from the marketplace. The caller must be the owner of the listing.
     *  This returns the equipment to the original owner and then deletes the record of listing.
     *
     *  @param id - The equipmentID to remove.
     *
     */
    function removeEquipment(uint256 id) public {
        Listing storage listing = listings[id];

        if (listing.owner != msg.sender) revert NotOwner();

        IERC721AQueryable(equipment).transferFrom(address(this), msg.sender, id);

        delete listings[id];

        emit ListingRemoved(id, msg.sender);
    }

    /**
     *
     *  @dev Withdraws all tokens to the owners address.
     *
     */
    function withdraw() public onlyOperator {
        payable(msg.sender).transfer(address(this).balance);
    }


     /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function materialListingByIndex(uint256 materialId, uint256 index) public view returns (MaterialListing memory) {
        require(index < totalMaterialListings(materialId), "Marketplace: out of bounds");
        return  _materialListings[materialId][index];
    }

    function _addMaterialListing(uint256 materialId, MaterialListing memory listing) private {
        _materialIndex[materialId][listing.id] = _materialListings[materialId].length;
        _materialListings[materialId].push(listing);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param listingId uint256 ID of the token to be removed from the tokens list
     */
    function _removeMaterialListing(uint256 materialId, uint256 listingId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastListingIndex = _materialListings[materialId].length - 1;
        uint256 listingIndex = _materialIndex[materialId][listingId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        MaterialListing memory lastListing = _materialListings[materialId][lastListingIndex];

        _materialListings[materialId][listingIndex] = lastListing; // Move the last token to the slot of the to-delete token
        _materialIndex[materialId][lastListing.id] = listingIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _materialIndex[materialId][listingId];
        _materialListings[materialId].pop();
    }
}