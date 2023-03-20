// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);

    function setPrice(address token, uint256 price) external;
}

contract DreamAcademyLending {
    IERC20 usdc;
    IPriceOracle dreamOracle;
    mapping(address => uint256) _balance;

    constructor(IPriceOracle _dreamOracle, address _tokenAddress) {
        dreamOracle = _dreamOracle;
        usdc = IERC20(_tokenAddress);
    }

    function initializeLendingProtocol(address tokenAddress) external payable {
        require(tokenAddress != address(0));
        require(msg.value > 0);

        _balance[msg.sender] += msg.value;
    }

    function balance() public view returns (uint256 amount) {
        return _balance[msg.sender];
    }

    function getAccruedSupplyAmount(
        address tokenAddress
    ) external returns (uint256 amount) {}

    function deposit(address tokenAddress, uint256 amount) external payable {
        if (tokenAddress == address(0)) {
            require(msg.value > 0);
            require(msg.value >= amount);
            _balance[msg.sender] += amount;
        } else {
            require(amount <= usdc.allowance(msg.sender, address(this)));
            usdc.transferFrom(
                msg.sender,
                address(this),
                amount + _balance[msg.sender]
            );
        }
    }

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
