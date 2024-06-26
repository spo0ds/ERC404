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
        uint256[] memory senderTokenId = exmp.getReverseNftTokensByCount(
            owner,
            transferAmount
        );
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

    function test_WhenOwnerApproveErc20TokenToAnotherAddress(
        uint256 tokenId
    ) external {
        vm.startPrank(owner);
        uint256 ownerBalanceBefore = exmp.balanceOfErc20(owner);
        exmp.approve(alice, 10 * 10e18);
        uint256 ownerBalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(ownerBalanceAfter, ownerBalanceBefore);
        assertEq(0, exmp.balanceOfErc20(alice));
        uint256 tokenCounter = exmp.tokenCounter();
        if (tokenId <= tokenCounter && tokenId > 0) {
            address nftOwner = exmp.ownerOfNft(tokenId);
            assertEq(nftOwner, owner);
        }
        vm.stopPrank();

        // now alice uses approved token to transfer to bob
        vm.startPrank(alice);
        uint256[] memory ownerTokenId = exmp.getReverseNftTokensByCount(
            owner,
            10
        );
        exmp.transferFrom(owner, bob, 10 * 10e18);
        uint256 bobErc20Balance = exmp.balanceOfErc20(bob);
        assertEq(10 * 10e18, bobErc20Balance);
        assertEq(ownerBalanceBefore - 10 * 10e18, exmp.balanceOfErc20(owner));
        for (uint256 i; i < 10; i++) {
            address nftOwner = exmp.ownerOfNft(ownerTokenId[i]);
            assertEq(nftOwner, bob);
        }
        vm.stopPrank();
    }

    function test_RevertWhen_NotApprovedAddressTriesToTransferBalance()
        external
    {
        vm.startPrank(owner);
        exmp.approve(alice, 10 * 10e18);
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert();
        exmp.transferFrom(owner, bob, 10 * 10e18);
        vm.stopPrank();
    }

    function test_WhenSomeoneSendsFractionalErc20Token() external {
        // it sould check the balance of erc20 from before and it not whole much burn that much nft.
        vm.startPrank(owner);
        uint256 burnedToken = exmp.getLastNftToken(owner);
        exmp.transfer(alice, 10e17);
        assertEq(address(0), exmp.ownerOfNft(burnedToken));
        uint256 tokenBalance = exmp.balanceOfErc20(owner);
        assertEq(tokenBalance, total_supply * 10e18 - 10e17);

        // checking for 2 fractional equal to 1 whole
        uint256 burnedTokenNew = exmp.getLastNftToken(owner);
        uint256 tokenCounterBefore = exmp.tokenCounter();
        uint256 ownerBeforeBalance = exmp.balanceOfErc20(owner);
        exmp.transfer(bob, 5 * 10e17);
        assertEq(owner, exmp.ownerOfNft(burnedTokenNew)); // no nft has been burned now
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
        uint256 mintedTokenId = exmp.getLastNftToken(bob);
        address newIdOwner = exmp.ownerOfNft(mintedTokenId); // tokenCounterAfter same
        assertEq(bob, newIdOwner);
        vm.stopPrank();
    }

    function test_WhenOwnerApproveFractionalErc20TokenToAnotherAddress(
        uint256 tokenId
    ) external {
        vm.startPrank(owner);
        uint256 ownerBalanceBefore = exmp.balanceOfErc20(owner);
        exmp.approve(alice, 10e18);
        uint256 ownerBalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(ownerBalanceAfter, ownerBalanceBefore);
        assertEq(0, exmp.balanceOfErc20(alice));
        uint256 tokenCounter = exmp.tokenCounter();
        if (tokenId <= tokenCounter && tokenId > 0) {
            address nftOwner = exmp.ownerOfNft(tokenId);
            assertEq(nftOwner, owner);
        }
        vm.stopPrank();
        // now alice uses approved token to transfer to bob
        vm.startPrank(alice);
        uint256 ownerTokenId = exmp.getLastNftToken(owner);
        exmp.transferFrom(owner, bob, 5 * 10e17);
        uint256 bobErc20Balance = exmp.balanceOfErc20(bob);
        assertEq(5 * 10e17, bobErc20Balance);
        assertEq(ownerBalanceBefore - 5 * 10e17, exmp.balanceOfErc20(owner));
        address newNftOwner = exmp.ownerOfNft(ownerTokenId);
        assertEq(newNftOwner, address(0));
        exmp.transferFrom(owner, bob, 5 * 10e17);
        tokenCounter = exmp.tokenCounter();
        address bobNftOwner = exmp.ownerOfNft(tokenCounter);
        assertEq(bobNftOwner, bob);
        ownerTokenId = exmp.getLastNftToken(owner);
        address burntNftOwner = exmp.ownerOfNft(ownerTokenId);
        assertEq(burntNftOwner, owner);
        vm.stopPrank();
    }

    function test_WhenERC20TokenIsMinted() external {
        vm.startPrank(owner);
        // it should mint nft if the erc20 amount is whole
        uint256 tokenCounter = exmp.tokenCounter();
        uint256 Erc20Balance = exmp.balanceOfErc20(owner);
        exmp.mintErc20(owner, 1 * 10e18);
        uint256 Erc20BalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(Erc20Balance + 10e18, Erc20BalanceAfter);
        uint256 newTokenCounter = exmp.tokenCounter();
        assertEq(tokenCounter + 1, newTokenCounter);

        // it should not mint nft if the erc20 amount is not whole
        tokenCounter = exmp.tokenCounter();
        exmp.mintErc20(owner, 5 * 10e17);
        newTokenCounter = exmp.tokenCounter();
        assertEq(tokenCounter, newTokenCounter);
        vm.stopPrank();
    }

    function test_WhenErc20TokenIsBurned() external {
        vm.startPrank(owner);
        // it should burn the nft
        uint256 tokenId = exmp.getLastNftToken(owner);
        address nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, owner);
        uint256 erc20BalanceBefore = exmp.balanceOfErc20(owner);
        exmp.burnErc20(owner, 1 * 10e18);
        uint256 erc20BalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(erc20BalanceAfter + 10e18, erc20BalanceBefore);
        nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, address(0));

        // while burning fractional erc20 token
        tokenId = exmp.getLastNftToken(owner);
        nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, owner);
        exmp.burnErc20(owner, 5 * 10e17); // burn checking of range remaining to implement
        nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, address(0));
        vm.stopPrank();
    }

    // function test_WhenNftIsBurned() external {
    //     vm.startPrank(owner);
    //     uint256 ownerTokenId = exmp.getLastNftToken(owner);
    //     address nftOwner = exmp.ownerOfNft(ownerTokenId);
    //     assertEq(nftOwner, owner);
    //     uint256 erc20BalanceBefore = exmp.balanceOfErc20(owner);
    //     uint256 tokenCounter = exmp.tokenCounter();
    //     exmp.burnNft(ownerTokenId);
    //     uint256 newTokenCounter = exmp.tokenCounter();
    //     assertEq(tokenCounter, newTokenCounter);
    //     uint256 erc20BalanceAfter = exmp.balanceOfErc20(owner);
    //     assertEq(erc20BalanceAfter, erc20BalanceBefore);
    //     nftOwner = exmp.ownerOfNft(ownerTokenId);
    //     assertEq(nftOwner, address(0));
    //     vm.stopPrank();
    // }

    function test_WhenNftIsTransferred() external {
        vm.startPrank(owner);
        uint256 tokenId = exmp.getLastNftToken(owner);
        address nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, owner);
        uint256 erc20BalanceBefore = exmp.balanceOfErc20(owner);
        exmp.transfer(alice, tokenId);
        uint256 erc20BalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(erc20BalanceAfter, erc20BalanceBefore);
        nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, alice);
        vm.stopPrank();
    }

    function test_WhenNftIsApproved() external {
        // it should only allow approved address to use that nft without changing erc20 balance
        vm.startPrank(owner);
        uint256 tokenId = exmp.getLastNftToken(owner);
        address nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, owner);
        uint256 erc20BalanceBefore = exmp.balanceOfErc20(owner);
        exmp.approve(alice, tokenId);
        vm.stopPrank();
        vm.startPrank(alice);
        exmp.transferFrom(owner, bob, tokenId);
        uint256 erc20BalanceAfter = exmp.balanceOfErc20(owner);
        assertEq(erc20BalanceAfter, erc20BalanceBefore);
        nftOwner = exmp.ownerOfNft(tokenId);
        assertEq(nftOwner, bob);
        vm.stopPrank();
    }

    function test_WhenRecieverHasFullErc20Gets1Nft() external {
        vm.startPrank(owner);
        uint256 tokenCounterBefore = exmp.tokenCounter();
        exmp.mintErc20(bob, 5 * 10e17);
        uint256 tokenCounterAfter = exmp.tokenCounter();
        assertEq(tokenCounterAfter, tokenCounterBefore);
        exmp.transfer(bob, 5 * 10e17);
        uint256 tokenCounterNew = exmp.tokenCounter();
        assertEq(tokenCounterAfter + 1, tokenCounterNew);
        vm.stopPrank();
    }
}
