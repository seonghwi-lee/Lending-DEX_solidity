// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Dex {
    constructor(address _token1, address _token2) {}

    function swap(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 tokenMinimumOutputAmount
    ) external returns (uint256 outputAmount) {}

    function addLiquidity(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 minimumLPTokenAmount
    ) external returns (uint256 LPTokenAmount) {}

    function removeLiquidity(
        uint256 LPTokenAmount,
        uint256 minimumTokenXAmount,
        uint256 minimumTokenYAmount
    ) external returns (uint256 _tx, uint256 _ty) {}

    function transfer(address to, uint256 lpAmount) external returns (bool) {}
}
