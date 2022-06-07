// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/ICoin.sol";
import "./interfaces/IEquipment.sol";
import "./token/ERC721/extensions/IERC721AQueryable.sol";
import "./access/Operator.sol";

contract MarketPlace is Operator {

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

    function getListings() public view returns (Listing[] memory) {
        uint256[] memory saleIDs = IERC721AQueryable(equipment).tokensOfOwner(address(this));

        return _getListingsFromIds(saleIDs);
    }

    function _getListingsFromIds(uint256[] memory tokenIds) internal view returns (Listing[] memory list) {
        for (uint i; i < tokenIds.length; i++) {
            list[i] = listings[tokenIds[i]];
        }
    }

    function add(uint256 id, uint256 price) external {
        IERC721AQueryable(equipment).transferFrom(msg.sender, address(this), id);
        listings[id] = Listing(msg.sender, price);

        emit NewListing(id, msg.sender, price);
    }

    function buy(uint256 id) public payable {
        Listing storage listing = listings[id];

        if (msg.value < listing.price) revert InsufficientPayment();
        if (listing.owner == address(0)) revert ItemDoesNotExist();

        IERC721A(equipment).transferFrom(address(this), msg.sender, id);

        payable(listing.owner).transfer(listing.price * (10000 - fee)  / 10000);

        delete listings[id];

        emit ItemSold(id, msg.sender, listing.price);
    }

    function remove(uint256 id) public {
        Listing storage listing = listings[id];

        if (listing.owner != msg.sender) revert NotOwner();

        IERC721AQueryable(equipment).transferFrom(address(this), msg.sender, id);

        delete listings[id];

        emit ListingRemoved(id, msg.sender);
    }

    function withdraw() public onlyOperator {
        payable(msg.sender).transfer(address(this).balance);
    }
}