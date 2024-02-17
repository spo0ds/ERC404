// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Example} from "../src/Example.sol";

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
        // it transfer that erc20 and nft to the receiver.
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
        vm.startPrank(owner);
        uint256[] memory senderTokenId = exmp.getAllNftTokens(owner);
        uint256 burnedToken = senderTokenId[senderTokenId.length - 1];
        assertEq(senderTokenId.length, 10_000);
        exmp.transfer(alice, 10e17);
        assertEq(address(0), exmp.ownerOfNft(burnedToken));
        uint256 tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, total_supply * 10e18 - 10e17);

        // checking for 2 fractional equal to 1 whole
        uint256[] memory senderTokenIdNew = exmp.getAllNftTokens(owner);
        uint256 burnedTokenCounter = senderTokenIdNew[
            senderTokenIdNew.length - 1
        ];
        uint256 tokenCounterBefore = exmp.tokenCounter();
        uint256 ownerBeforeBalance = exmp.balanceOfErc20(owner);
        exmp.transfer(bob, 5 * 10e17);
        assertEq(address(0), exmp.ownerOfNft(burnedTokenCounter)); // need to remove ids from the holders mapping array
        tokenBalance = exmp.balanceOfErc20(bob);
        assertEq(tokenBalance, 5 * 10e17);
        tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, ownerBeforeBalance - 5 * 10e17);
        uint256 tokenCounterAfter = exmp.tokenCounter();
        assertEq(tokenCounterBefore, tokenCounterAfter);
        exmp.transfer(bob, 5 * 10e17);
        assertEq(10e18, exmp.balanceOfErc20(bob));
        tokenCounterAfter = exmp.tokenCounter();
        assertEq(tokenCounterAfter, tokenCounterBefore + 1);
        uint256[] memory senderTokenId2 = exmp.getAllNftTokens(bob);
        uint256 holdernewBalance = senderTokenId2.length;
        uint256 mintedToken = senderTokenId2[holdernewBalance - 1];
        address newIdOwner = exmp.ownerOfNft(mintedToken); // tokenCounterAfter same
        assertEq(bob, newIdOwner);
        vm.stopPrank();
    }
    // prevent double burning like if address 1 sends fractional 0.5 token 1 nft is burned and again if address 1 sends 0.5 token again nft is burned but we need only one nft to be burned.
    // maybe put a flag to indicate nft is already burned for that range fractional erc20 value
}
