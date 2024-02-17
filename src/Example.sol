//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC404} from "./ERC404.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Example is ERC404 {
    constructor(address owner) ERC404("Example", "EXM", 10_000 * 10e18) {
        _mintErc20(owner, 10_000 * 10e18);
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        return
            string.concat("https://example.com/token/", Strings.toString(id));
    }
}
