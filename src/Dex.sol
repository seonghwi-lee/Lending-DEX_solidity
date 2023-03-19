// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CustomERC20} from "../test/Dex.t.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    IERC20 private tokenX;
    IERC20 private tokenY;

    address private owner;
    mapping(address => uint) _lpBalances;
    uint256 k;

    constructor(address _tokenX, address _tokenY) {
        k = _tokenX.balance * _tokenY.balance;
        owner = msg.sender;
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
    }

    function swap(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 tokenMinimumOutputAmount
    ) external returns (uint256 outputAmount) {}

    function addLiquidity(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 minimumLPTokenAmount
    ) external returns (uint256 LPTokenAmount) {
        require(tokenXAmount == tokenYAmount);
        require(tokenXAmount != 0 && tokenYAmount != 0);
        require(
            tokenX.allowance(msg.sender, address(this)) >= tokenXAmount &&
                tokenY.allowance(msg.sender, address(this)) >= tokenYAmount,
            "ERC20: insufficient allowance"
        );
        require(
            tokenX.balanceOf(msg.sender) >= tokenXAmount &&
                tokenY.balanceOf(msg.sender) >= tokenYAmount,
            "ERC20: transfer amount exceeds balance"
        );

        if (minimumLPTokenAmount > tokenXAmount) revert();

        tokenX.transferFrom(msg.sender, address(this), tokenXAmount);
        tokenY.transferFrom(msg.sender, address(this), tokenYAmount);
        _lpBalances[msg.sender] += tokenXAmount;
        return tokenXAmount;
    }

    function removeLiquidity(
        uint256 LPTokenAmount,
        uint256 minimumTokenXAmount,
        uint256 minimumTokenYAmount
    ) external returns (uint256 _tx, uint256 _ty) {
        require(LPTokenAmount != 0);
        require(
            minimumTokenXAmount <= LPTokenAmount &&
                minimumTokenYAmount <= LPTokenAmount
        );
        require(this.transfer(msg.sender, LPTokenAmount));
        return (LPTokenAmount, LPTokenAmount);
    }

    function transfer(address to, uint256 lpAmount) external returns (bool) {
        require(to != address(0));
        require(_lpBalances[to] >= lpAmount);

        _lpBalances[to] -= lpAmount;

        tokenX.transfer(to, lpAmount);
        tokenY.transfer(to, lpAmount);

        return true;
    }
}
