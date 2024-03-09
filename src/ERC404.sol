// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Context} from "./Context.sol";
import {console} from "forge-std/console.sol";

error NotNftOwner();
error InvalidReceiver(address);
error InvalidSender(address);
error ERC20InsufficientBalance(address, uint256, uint256);
error NftNotApproved(address);
error ERC20InsufficientAllowance(address, uint256, uint256);
error ERC721NonexistentToken(uint256);

abstract contract ERC404 is Context {
    string private i_name;
    string private i_symbol;
    uint256 private i_totalSupply;
    uint256 private i_tokenCounter;

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
    // which address holds which nfts?
    mapping(address => uint256[] nftIds) private _nftHolders;

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

    function tokenCounter() public view virtual returns (uint256) {
        return i_tokenCounter;
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

    function getAllNftTokens(
        address _address
    ) public view returns (uint256[] memory) {
        return _nftHolders[_address];
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
            approveErc20(caller, spender, amountOrId);
        }
        emit Approval(caller, spender, amountOrId);
        return true;
    }

    function approveErc20(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowancesErc20[owner][spender] = amount;
        uint256 erc20Amount = amount / 10e18;
        if (erc20Amount > 0) {
            uint256[] memory senderTokenId = getAllNftTokens(owner);
            for (uint i = 0; i < erc20Amount; i++) {
                _nftApprovals[senderTokenId[i]] = spender;
            }
        }
    }

    function transfer(
        address to,
        uint256 amountOrId
    ) public virtual returns (bool) {
        address owner = _msgSender();
        if (isNftToken(amountOrId)) {
            _updateNft(owner, to, amountOrId);
        } else {
            uint256 erc20Amount = amountOrId / 10e18;
            if (erc20Amount > 0) {
                uint256[] memory senderTokenId = getAllNftTokens(owner);
                for (uint i = 0; i < erc20Amount; i++) {
                    _updateNft(owner, to, senderTokenId[i]);
                }
            }
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
                if (10e18 > value) {
                    uint256[] memory tokenId = getAllNftTokens(from);
                    uint256 token = tokenId[tokenId.length - 1];
                    if (fromBalance % 10e18 == 0) {
                        _nftHolders[from].pop();
                        _burnNft(token);
                    }
                }
            }
        }
        if (to == address(0)) {
            uint256 tokenLength = getAllNftTokens(from).length;
            if (value <= 10e18) {
                if (_balancesErc20[from] % 10e18 == 0) {
                    _nftHolders[from].pop();
                    _burnNft(tokenLength);
                }
            }
            unchecked {
                i_totalSupply -= value;
            }
        } else {
            unchecked {
                _balancesErc20[to] += value;
                if (value <= 10e18) {
                    if (_balancesErc20[to] / 10e18 == 1) {
                        _mintNft(to, ++i_tokenCounter);
                    }
                }
            }
        }
        emit Transfer(from, to, value);
    }

    function _updateNft(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual returns (address) {
        address owner = ownerOfNft(tokenId);
        if (owner != from) {
            address spender = _getNftApproved(tokenId);
            if (spender != from) {
                revert NftNotApproved(from);
            }
        }
        _ownersNft[tokenId] = to;
        emit Transfer(from, to, tokenId);
        return owner;
    }

    function isNftToken(
        uint256 amountOrId
    ) internal view virtual returns (bool) {
        return amountOrId <= i_tokenCounter && amountOrId > 0;
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
                revert ERC20InsufficientAllowance(
                    spender,
                    allowedAmount,
                    amountOrId
                );
            }
            approveErc20(from, spender, allowedAmount - amountOrId);
            uint256 erc20Amount = amountOrId / 10e18;
            if (erc20Amount > 0) {
                uint256[] memory senderTokenId = getAllNftTokens(from);
                for (uint i = 0; i < erc20Amount; i++) {
                    _updateNft(from, to, senderTokenId[i]);
                }
            }
            _updateErc20(from, to, amountOrId);
        }
        return true;
    }

    function _mintErc20(address account, uint256 value) internal {
        if (account == address(0)) {
            revert InvalidReceiver(address(0));
        }
        uint256 erc20Amount = value / 10e18;
        if (erc20Amount > 0) {
            for (uint i = 0; i < erc20Amount; i++) {
                _mintNft(_msgSender(), ++i_tokenCounter);
            }
        }
        _updateErc20(address(0), account, value);
    }

    function _mintNft(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert InvalidReceiver(address(0));
        }
        _nftHolders[to].push(tokenId);
        address previousOwner = _updateNft(address(0), to, tokenId);
        if (previousOwner != address(0)) {
            revert InvalidSender(address(0));
        }
    }

    function _burnErc20(address account, uint256 value) internal {
        if (account == address(0)) {
            revert InvalidSender(address(0));
        }
        _updateErc20(account, address(0), value);
    }

    function _burnNft(uint256 tokenId) internal {
        address previousOwner = _updateNft(address(0), address(0), tokenId);
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }
}
