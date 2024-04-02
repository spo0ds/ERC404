// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Example} from "../.././src/Example.sol";

contract StatelessFuzzing is Test {
    Example public exmp;
    address owner = address(1);
    address alice = address(2);

    function setUp() public {
        exmp = new Example(owner);
    }

    function test_FuzzBalanceOfERC20AndNft(uint256 erc20Amount) public {
        erc20Amount = bound(erc20Amount, 1, 100);
        vm.startPrank(owner);
        exmp.mintErc20(owner, erc20Amount * 10e18);
        vm.stopPrank();
        uint256 erc20Balace = exmp.balanceOfErc20(owner);
        uint256[] memory tokenIds = exmp.getAllNftTokens(owner);
        assertEq(erc20Balace / 10e18, tokenIds.length);
    }
}
