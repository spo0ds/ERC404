// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity  ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}