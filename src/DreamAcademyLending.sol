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
    mapping(address => uint256) _reserve;
    mapping(address => uint256) _borrowed;
    uint256 loanToValue;
    uint256 liquidThreshold;

    constructor(IPriceOracle _dreamOracle, address _tokenAddress) {
        dreamOracle = _dreamOracle;
        usdc = IERC20(_tokenAddress);
        loanToValue = 50;
        liquidThreshold = 75;
    }

    function initializeLendingProtocol(address tokenAddress) external payable {
        require(tokenAddress != address(0));
        require(msg.value > 0);

        _reserve[msg.sender] += msg.value;
    }

    function balance() public view returns (uint256 amount) {
        return _reserve[msg.sender];
    }

    function getAccruedSupplyAmount(
        address tokenAddress
    ) external returns (uint256 amount) {}

    function deposit(address tokenAddress, uint256 amount) external payable {
        if (tokenAddress == address(usdc)) {
            require(amount <= usdc.allowance(msg.sender, address(this)));
            usdc.transferFrom(
                msg.sender,
                address(this),
                amount + _reserve[msg.sender]
            );
        } else {
            require(msg.value >= amount);
            _reserve[msg.sender] += amount;
        }
    }

    function borrow(address tokenAddress, uint256 amount) external {
        uint256 curValue = dreamOracle.getPrice(tokenAddress) * (amount / 1e18);
        if (tokenAddress == address(usdc)) {
            require(
                curValue + _borrowed[msg.sender] <=
                    (dreamOracle.getPrice(address(usdc)) *
                        (_reserve[msg.sender] / 1e18) *
                        loanToValue) /
                        100
            );
            _reserve[msg.sender] += curValue;
            _borrowed[msg.sender] += curValue;

            usdc.transfer(msg.sender, amount);
        }
    }

    function repay(address tokenAddress, uint256 amount) external {}

    function liquidate(
        address user,
        address tokenAddress,
        uint256 amount
    ) external {}

    function withdraw(address tokenAddress, uint256 amount) external {}

    receive() external payable {}
}
