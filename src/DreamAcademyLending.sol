// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPriceOracle {}

contract DreamAcademyLending {
    constructor(IPriceOracle dreamOracle, address tokenAddress) {}

    function initializeLendingProtocol(address tokenAddress) external payable {}

    function getAccruedSupplyAmount(
        address tokenAddress
    ) external returns (uint256 amount) {}

    function deposit(address tokenAddress, uint256 amount) external payable {}

    function borrow(address tokenAddress, uint256 amount) external {}

    function repay(address tokenAddress, uint256 amount) external {}

    function liquidate(
        address user,
        address tokenAddress,
        uint256 amount
    ) external {}

    function withdraw(address tokenAddress, uint256 amount) external {}

    receive() external payable {}
}
