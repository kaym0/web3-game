// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/***
 *
 *  @title Operator
 *
 *  @version 0.0.1
 *
 *  @custom:experimental
 *
 *  @author kaymo.eth
 *
 *  A unique implementation of contract ownership which allows for both a master operator and an unlimited amount of child operators.
 *  Child operators can, with permission, add and remove other operators. Likewise, without that permission they cannot.
 *  This allows for specific addresses to have an elevated permission in the child contract while being unable to remove operators themselves,
 *  this proves a unique utility that expands the possibilities and use-cases for the original operator and ownable implementations.
 *
 */
contract Operator  {
    
    address public masterOperator;
    bool public operatorsCanWrite;

    mapping (address => bool) public operators;

    uint8 permissions = 0;

    constructor() {
        masterOperator = msg.sender;
        operators[msg.sender] = true;
    }

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event MasterOperatorChanged(address indexed operator);

    error NotOperator();
    error InsufficientPrivileges();
    error NotMasterOperator();
    error CannotRemoveMasterOperator();

    modifier onlyMasterOperator {
        if (msg.sender != masterOperator) revert NotMasterOperator();
        _;
    }

    modifier onlyOperator {
        if (operators[msg.sender] == false) revert NotOperator();
        _;
    }

    /**
     *
     *  @dev Transfers master operator to a selected address.
     *
     *  @param operator - The new master operator.
     *
     */
    function transferMasterOperator(address operator) public onlyMasterOperator {
        masterOperator = operator;

        emit MasterOperatorChanged(operator);
    }

    /**
     *
     *  @dev Transfers master operator status to the zero address, thereby removing master operator status entirely.
     *
     *  @notice This cannot be undone. It's important to make sure that the operatorsCanWrite variable is set correctly before doing this
     *
     */
    function relinquishOwnership() public onlyMasterOperator {
        masterOperator = address(0);
        emit MasterOperatorChanged(address(0));
    }

    /**
     * 
     *  @dev Removes an operator to the contract
     *
     *  @notice The master operator cannot be removed, even by themselves. To reliquish ownership, use relinquishOwnership();
     *
     *  @param operator - The new operator
     *
     */
    function removeOperator(address operator) public onlyOperator {
        if (masterOperator == operator) revert CannotRemoveMasterOperator();
        if (operatorsCanWrite == false && masterOperator != msg.sender) revert InsufficientPrivileges();
        operators[operator] = false;

        emit OperatorRemoved(operator);
    }

    /**
     * 
     *  @dev Adds an operator to the contract
     *
     *  @notice operatorsCanWrite is required to be set to true for operators to be able to add other operators. Otherwise,
     *  only the master operator is able to use this function.
     *
     *  @param operator - The new operator
     *
     */
    function addOperator(address operator) public onlyOperator {
        if (operatorsCanWrite == false && masterOperator != msg.sender) revert InsufficientPrivileges();

        operators[operator] = true;

        emit OperatorAdded(operator);
    }
}