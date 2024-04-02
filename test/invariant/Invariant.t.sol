// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Example} from "../.././src/Example.sol";
import {Handler} from "./Handler.t.sol";

/*
    If account A transfers 1 whole ERC20 token to account B then NFT is transferred from account A to account B.
    If account A transfers fractional ERC20 token to account B;
        -> If the receiving account balance becomes whole, mint new nft.
        -> If before transferring the balance was whole, burn the nft.
        -> If before transferring the balance was not whole, do nothing with the nft.
        -> If receiving account balance will not be whole, do nothing with the nft.
    Above condition apply for approving but it doesn't do anything with the nft while approving to other account.

    Without Nft Burn features, invariant is erc20 balance / 10e18 == no of nfts
*/

contract Invariant is StdInvariant, Test {
    Example public exmp;
    Handler public handler;
    address owner = address(1);
    address alice = address(2);
    address bob = address(3);

    function setUp() external {
        vm.startPrank(owner);
        exmp = new Example(owner);
        vm.stopPrank();

        handler = new Handler(exmp, owner, alice, bob);
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = handler.transfer.selector;
        selectors[1] = handler.transferFrom.selector;
        selectors[2] = handler.approve.selector;
        selectors[3] = handler.mintErc20.selector;
        selectors[4] = handler.burnErc20.selector;
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function statefulFuzz__testInvariantWholeErc20Transfer() public {
        uint256 erc20Balace = exmp.balanceOfErc20(owner);
        uint256[] memory tokenIds = exmp.getAllNftTokens(owner);
        assertEq(erc20Balace / 10e18, tokenIds.length);
    }
}
