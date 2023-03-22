// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);

    function setPrice(address token, uint256 price) external;
}

contract DreamAcademyLending {
    IERC20 usdc;
    IPriceOracle dreamOracle;
    mapping(address => mapping(address => uint256)) _reserve;
    mapping(address => mapping(address => uint256)) _borrowed;
    mapping(address => uint256) _totalReserve;
    mapping(address => uint256) _totalBorrowed;
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

        _totalReserve[msg.sender] += msg.value;
    }

    function getAccruedSupplyAmount(
        address tokenAddress
    ) external returns (uint256 amount) {}

    function deposit(address tokenAddress, uint256 amount) external payable {
        if (tokenAddress == address(usdc)) {
            require(amount <= usdc.allowance(msg.sender, address(this)));
            _reserve[msg.sender][tokenAddress] += amount;
            _totalReserve[msg.sender] += getReserve();
            usdc.transferFrom(
                msg.sender,
                address(this),
                _totalReserve[msg.sender]
            );
            _totalReserve[msg.sender] = 0;
        } else {
            require(msg.value >= amount);
            _reserve[msg.sender][tokenAddress] += amount;
            getReserve();
        }
    }

    function borrow(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(usdc)) {
            require(
                amount + getBorrowed() <= (getReserve() * loanToValue) / 100
            );

            usdc.transfer(msg.sender, amount);
        } else {
            require(getReserve() >= amount + getBorrowed());
        }
        _borrowed[msg.sender][tokenAddress] += amount;
        _totalBorrowed[msg.sender] += amount;
    }

    function repay(address tokenAddress, uint256 amount) external {}

    function liquidate(
        address user,
        address tokenAddress,
        uint256 amount
    ) external {}

    function checkLTV(
        address tokenAddress,
        uint256 amount
    ) internal view returns (bool) {
        if (
            ((_reserve[msg.sender][tokenAddress] - amount) * loanToValue) /
                100 >=
            _totalBorrowed[msg.sender]
        ) {
            return true;
        }
        return false;
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        require(checkLTV(tokenAddress, amount));
        _reserve[msg.sender][tokenAddress] -= amount;
    }

    receive() external payable {}

    function getReserve() internal returns (uint256 reserveValue) {
        reserveValue =
            getCurReserveValue(address(0)) +
            getCurReserveValue(address(usdc));
    }

    function getCurReserveValue(
        address tokenAddress
    ) internal returns (uint256 curValue) {
        curValue =
            (_reserve[msg.sender][tokenAddress] / 1e18) *
            dreamOracle.getPrice(tokenAddress);
    }

    function getBorrowed() internal returns (uint256 borrowValue) {
        borrowValue =
            getBorrowValue(address(0)) +
            getBorrowValue(address(usdc));
    }

    function getBorrowValue(
        address tokenAddress
    ) internal returns (uint256 borrowValue) {
        borrowValue = (_borrowed[msg.sender][tokenAddress]);
    }
}
