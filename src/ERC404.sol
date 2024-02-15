pragma solidity ^0.8.0;

import {Context} from "./Context.sol";

abstract contract ERC404 is Context{
    string private i_name;
    string private i_symbol;

    // how many erc20 token account holds? 
    mapping(address account => uint256) private _balances; 
    // how many erc20 token account has approved to the spender?
    mapping(address account => mapping(address spender => uint256)) private _allowances; 
    // who's the owner of erc721 token?
    mapping(uint256 tokenId => address) private _owners;
    // which token is approved to address?
    mapping(uint256 tokenId => address) private _tokenApprovals;

    constructor(string memory _name, string memory _symbol){
        i_name = _name;
        i_symbol = _symbol;
    }

    function name() public view virtual returns (string memory) {
        return i_name;
    }

    function symbol() public view virtual returns (string memory) {
        return i_symbol;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
}