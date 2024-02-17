// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Example} from "../src/Example.sol";

import "forge-std/console.sol";

contract testExample is Test {
    Example public exmp;
    address owner = address(1);
    address alice = address(2);
    address bob = address(3);
    uint256 total_supply = 10_000;

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
        assertEq(tokenBalance, total_supply * 10e18);
        uint256 tokenCounter = exmp.tokenCounter(); // token counter is automatically incremented while minting
        assertEq(tokenCounter, total_supply);
        if (tokenId <= tokenCounter && tokenId > 0) {
            address nftOwner = exmp.ownerOfNft(tokenId);
            assertEq(nftOwner, owner);
        }
        vm.stopPrank();
    }

    function test_WhenSomeoneSend1WholeErc20Token() external {
        // it transfer that erc20 and mint that much nft to the receiver.
        uint256 transferAmount = 10;
        vm.startPrank(owner);
        uint256 tokenCounterBefore = exmp.tokenCounter();
        uint256[] memory senderTokenId = exmp.getAllNftTokens(owner);
        exmp.transfer(alice, transferAmount * 10e18);
        uint256 tokenBalance = exmp.balanceOfErc20(alice);
        assertEq(tokenBalance, transferAmount * 10e18);
        tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, (total_supply - transferAmount) * 10e18);
        uint256 tokenCounterAfter = exmp.tokenCounter();
        for (uint256 i = 0; i < transferAmount; ++i) {
            address nftOwner = exmp.ownerOfNft(senderTokenId[i]);
            assertEq(nftOwner, alice);
        }
        assertEq(tokenCounterAfter, tokenCounterBefore); // no any additional minting of Nfts
        vm.stopPrank();
    }

    function test_WhenSomeoneSendsFractionalErc20Token() external {
        // it sould check the balance of erc20 from before and it not whole much burn that much nft.
        uint256 transferAmount = 1;
        vm.startPrank(owner);
        uint256[] memory senderTokenId = exmp.getAllNftTokens(owner);
        exmp.transfer(alice, transferAmount * 10e17);
        uint256 tokenBalance = exmp.balanceOfErc20(alice);
        assertEq(tokenBalance, transferAmount * 10e17);
        tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, total_supply * 10e18 - transferAmount * 10e17);
        for (uint256 i = 0; i < transferAmount; ++i) {
            address nftOwner = exmp.ownerOfNft(senderTokenId[i]);
            assertEq(nftOwner, owner);
        }
        vm.stopPrank();
    }
}
