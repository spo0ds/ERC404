// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Example} from "../.././src/Example.sol";

contract Handler is Test {
    Example public exmp;
    address owner;
    address alice;
    address bob;

    constructor(
        Example _example,
        address _owner,
        address _alice,
        address _bob
    ) {
        exmp = _example;
        owner = _owner;
        alice = _alice;
        bob = _bob;
    }

    modifier mint(uint256 depositAmount) {
        depositAmount = bound(depositAmount, 1, 100);
        vm.startPrank(owner);
        exmp.mintErc20(owner, depositAmount * 10e18);
        _;
    }

    function transfer(uint256 amount) public mint(amount) {
        amount = bound(amount, 1, 100);
        vm.startPrank(owner);
        exmp.transfer(alice, amount * 10e18);
        vm.stopPrank();
    }

    function transferFrom(uint256 amount) public mint(amount) {
        amount = bound(amount, 1, 100);
        vm.startPrank(owner);
        exmp.approve(alice, amount * 10e18);
        vm.stopPrank();
        vm.startPrank(alice);
        exmp.transferFrom(owner, bob, amount * 10e18);
        vm.stopPrank();
    }

    function approve(uint256 amount) public mint(amount) {
        amount = bound(amount, 1, 100);
        vm.startPrank(owner);
        exmp.approve(alice, amount * 10e18);
        vm.stopPrank();
    }

    function mintErc20(uint256 value) public mint(value) {}

    function burnErc20(uint256 value) public {
        value = bound(value, 1, 100);
        vm.startPrank(owner);
        exmp.burnErc20(owner, value);
    }
}
