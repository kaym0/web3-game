// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/ICoin.sol";
import "./interfaces/IEquipment.sol";
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
 *  @version 0.0.1
 *
 *  A marketplace where players can buy and sell their equipment and items for currency. 
 *
 *  This is an early-strage contract which is currently experimental and being built with the intention of further development. 
 *
 */
contract Marketplace is Operator {

    uint256 public fee = 250; // 2.5%
    address public equipment;
    address public coin;

    mapping (uint256 => Listing) public listings;

    constructor(address _equipment, address _coin) {
        equipment = _equipment;
        coin = _coin;
    }

    struct Listing {
        address owner;
        uint256 price;
    }

    event NewListing        (uint256 indexed tokenId, address indexed owner, uint256 indexed price);
    event ItemSold          (uint256 indexed tokenId, address indexed buyer, uint256 indexed price);
    event ListingRemoved    (uint256 indexed tokenId, address indexed owner);

    error InsufficientPayment();
    error ItemDoesNotExist();
    error NotOwner();


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
    function _getListingsFromIds(uint256[] memory tokenIds) internal view returns (Listing[] memory list) {
        for (uint i; i < tokenIds.length; i++) {
            list[i] = listings[tokenIds[i]];
        }
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
    function add(uint256 id, uint256 price) external {
        IERC721AQueryable(equipment).transferFrom(msg.sender, address(this), id);
        listings[id] = Listing(msg.sender, price);

        emit NewListing(id, msg.sender, price);
    }

    /**
     *
     *  @dev Executes a purchase for a specific item. The correct amount of currency must be sent with this transaction, else it fails.
     *
     *  @param id - The equipmentID of the token to purchase.
     *
     */
    function buy(uint256 id) public payable {
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
    function remove(uint256 id) public {
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
}