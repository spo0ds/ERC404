// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Context} from "./Context.sol";

error NotNftOwner();
error InvalidReceiver(address);
error InvalidSender(address);
error ERC20InsufficientBalance(address, uint256, uint256);
error NftNotApproved(address);

abstract contract ERC404 is Context {
    string private i_name;
    string private i_symbol;
    uint256 private i_totalSupply;

    uint256 private tokenCounter;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amountOrId
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amountOrId
    );

    // how many erc20 token account holds?
    mapping(address => uint256) private _balancesErc20;
    // how many erc20 token account has approved to the spender?
    mapping(address => mapping(address => uint256)) private _allowancesErc20;
    // who's the owner of erc721 token?
    mapping(uint256 => address) private _ownersNft;
    // which token is approved to address?
    mapping(uint256 => address) private _nftApprovals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 totalSupply
    ) {
        i_name = _name;
        i_symbol = _symbol;
        i_totalSupply = totalSupply;
    }

    function name() public view virtual returns (string memory) {
        return i_name;
    }

    function symbol() public view virtual returns (string memory) {
        return i_symbol;
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function balanceOfErc20(
        address account
    ) public view virtual returns (uint256) {
        return _balancesErc20[account];
    }

    function AllowanceOfErc20(
        address account,
        address spender
    ) public view virtual returns (uint256) {
        return _allowancesErc20[account][spender];
    }

    function ownerOfNft(uint256 tokenId) public view virtual returns (address) {
        return _ownersNft[tokenId];
    }

    function _getNftApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        return _nftApprovals[tokenId];
    }

    function approve(
        address spender,
        uint256 amountOrId
    ) public virtual returns (bool) {
        address caller = _msgSender();
        if (isNftToken(amountOrId)) {
            address owner = ownerOfNft(amountOrId);
            if (caller != owner) {
                revert NotNftOwner();
            }
            _nftApprovals[amountOrId] = spender;
        } else {
            _allowancesErc20[caller][spender] = amountOrId;
        }
        emit Approval(caller, spender, amountOrId);
        return true;
    }

    function transfer(
        address to,
        uint256 amountOrId
    ) public virtual returns (bool) {
        address owner = _msgSender();
        if (isNftToken(amountOrId)) {
            _updateNft(owner, to, amountOrId);
        } else {
            _updateErc20(owner, to, amountOrId);
        }
        return true;
    }

    function _updateErc20(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (from == address(0)) {
            i_totalSupply += value;
        } else {
            uint256 fromBalance = _balancesErc20[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balancesErc20[from] = fromBalance - value;
            }
        }
        if (to == address(0)) {
            unchecked {
                i_totalSupply -= value;
            }
        } else {
            unchecked {
                _balancesErc20[to] += value;
            }
        }
        emit Transfer(from, to, value);
    }

    function _updateNft(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = ownerOfNft(tokenId);
        if (owner != from) {
            address spender = _getNftApproved(tokenId);
            if (spender != from) {
                revert NftNotApproved(from);
            }
        }
        _ownersNft[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function isNftToken(
        uint256 amountOrId
    ) internal view virtual returns (bool) {
        return amountOrId <= tokenCounter && amountOrId > 0;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual returns (bool) {
        address spender = _msgSender();
        if (isNftToken(amountOrId)) {
            _updateNft(from, to, amountOrId);
        } else {
            uint256 allowedAmount = AllowanceOfErc20(from, spender);
            if (allowedAmount < amountOrId) {
                revert("ERC20: transfer amount exceeds allowance");
            }
            approve(spender, allowedAmount - amountOrId);
            _updateErc20(from, to, amountOrId);
        }
        return true;
    }
}
