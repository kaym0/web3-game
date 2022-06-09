// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { CharacterStorage } from "../libraries/CharacterStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { LibAppStorage } from "../libraries/LibAppStorage.sol";
import { ERC721A } from "./ERC721AFacet.sol";

/**
 *  @title Character Token Contract
 *  @author kaymo.eth
 */
contract CharacterFacet is ERC721A {
    using SafeMath for uint256;

    error Initialized();

    function initialize() public onlyOwner {
        if (state.initialized) revert Initialized();
        state.initialized = true;
        _mint(state.tokenDisperser, 100_000_000 ether);
        _setupContractId("ChildMintableERC20");
        _grantRole(state.DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(state.DEPOSITOR_ROLE, _msgSender());
        _initializeEIP712("Pace"); 
    }

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Not owner");
        _;
    }

    function treasury() public view returns (address) {
        return state.treasury;
    }

    function communityWallet() public view returns (address) {
        return state.communityWallet;
    }

    function tokenDisperser() public view returns (address) {
        return state.tokenDisperser;
    }

    function taxPercentage() public view returns (uint256) {
        return state.taxPercentage;
    }

    function taxCount() public view returns (uint256) {
        return state.taxCount;
    }

    function burnOnTransfer() public view returns (bool) {
        return state.burnOnTransfer;
    }

    /**
     *  @dev View function. Checks whether or not a 
     *  specific account is excluded from tax.
     *  @param account - The account to check
     *  @return true if account is taxed
     */
    function excludedFromTax(address account) public view returns (bool) {
        return state.excludedFromTax[account];
    }

    /**
     *  @notice Used to disable taxing on a specific address, 
     *  community wallet, etc.
     *  @dev Excludes an address from tax.
     *  @param account - The account to exclude
     */
    function addExcludedAccount(address account) public onlyOwner {
        state.excludedFromTax[account] = true;
    }

    /**
     *  @notice Used to enable taxing on a specific address, 
     *  community wallet, etc.
     *  @dev Excludes an address from tax.
     *  @param account - The account to exclude
     */
    function removeExcludedAccount(address account) public onlyOwner {
        state.excludedFromTax[account] = false;
    }

    /**
     *  @dev Toggles burning on and off.
     *  @notice This also adjusts the tax between 2% (burn = off) and 3% (burn = on) total. 
     *  This is because burn accounts 
     *  for 1/3 of the total tax.
     */
    function toggleBurn() public onlyOwner {
        if (state.burnOnTransfer) {
            state.taxCount = 2;
            state.burnOnTransfer = false;
            return;
        }

        state.burnOnTransfer = true;
        state.taxCount = 3;
    }

    /**
     *  @dev _transfer() override. Before transferring, applies 3% tax to token.
     *  @param from - The address tokens are being transferred from
     *  @param to - The address tokens are being transferred to
     *  @param amount - The amount of tokens being transferred
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 amountAfterTax = _transferFees(from, to, amount);
        uint256 fromBalance = state._balances[from];

        require(fromBalance >= amountAfterTax, "ERC20: transfer amount exceeds balance");

        unchecked {
            state._balances[from] = fromBalance - amountAfterTax;
        }

        state._balances[to] += amountAfterTax;

        emit Transfer(from, to, amountAfterTax);
    }

    /**
     *  @dev Taxes a fixed rate of 3%
     *  @notice Transfers 1% to treasury, 1% to community wallet, and then burns 1%.
     *  @param from - The address tokens are being moved from
     *  @param to - The address tokens are being moved to.
     *  @param amount - The total transfer amount
     *  @return amountAfterTax - The amount of tokens to send after tax is applied
     */
    function _transferFees(address from, address to, uint256 amount) internal virtual returns (uint256) {
        if (state.excludedFromTax[to]) return amount;
        if (state.excludedFromTax[from]) return amount;

        uint256 taxAmount = amount.mul(state.taxPercentage).div(10000);
        _transfer(from, state.treasury, taxAmount);
        _transfer(from, state.communityWallet, taxAmount);
        if (state.burnOnTransfer) _burn(from, taxAmount);
        return amount.sub(taxAmount.mul(state.taxCount));
    }
}
