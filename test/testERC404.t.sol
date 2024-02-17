// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Example} from "../src/Example.sol";

import "forge-std/console.sol";

contract testExample is Test {
    Example public exmp;
    address owner = address(1);

    function setUp() external {
        vm.startPrank(owner);
        exmp = new Example(owner);
        vm.stopPrank();
    }

    function test_WhenTotalSupplyIsPassedInConstructor(
        uint256 tokenId
    ) external {
        // it should mint that much erc20 and erc721 token.
        vm.startPrank(owner);
        uint256 tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, 10_000 * 10e18);
        uint256 tokenCounter = exmp.tokenCounter(); // token counter is automatically incremented while minting
        assertEq(tokenCounter, 10_000);
        if (tokenId <= 10_000 && tokenId > 0) {
            address nftOwner = exmp.ownerOfNft(tokenId);
            assertEq(nftOwner, owner);
        }
        vm.stopPrank();
    }

    function test_WhenSomeoneSend1WholeErc20Token() external {
        // it transfer that erc20 and mint that much nft to the receiver.
        // it should burn that much nft from the sender address.
    }

    function test_WhenSomeoneSendsFractionalErc20Token() external {
        // it sould check the balance of erc20 from before and it not whole much burn that much nft.
    }
}
