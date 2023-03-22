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
    mapping(address => mapping(address => uint256)) _reserve;
    mapping(address => mapping(address => uint256)) _borrowed;
    mapping(address => uint256) _totalReserve;
    mapping(address => uint256) _totalBorrowed;
    mapping(address => uint256) _borrwedTime;
    uint256 loanToValue;
    uint256 liquidThreshold;
    uint256 constant INTEREST_RATE = 100000013;
    uint256 constant INTEREST_RATE2 = 100000000;

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
            _totalReserve[msg.sender] += getReserve();
        }
    }

    function borrow(address tokenAddress, uint256 amount) external {
        if (_borrwedTime[msg.sender] == 0) {
            _borrwedTime[msg.sender] = block.number;
        }
        if (tokenAddress == address(usdc)) {
            require(
                amount + getBorrowed() <= (getReserve() * loanToValue) / 100
            );

            usdc.transfer(msg.sender, amount);
        } else {
            require(getReserve() >= amount + getBorrowed());
        }
        _borrowed[msg.sender][tokenAddress] += amount;
        _totalBorrowed[msg.sender] = getBorrowed();
    }

    function repay(address tokenAddress, uint256 amount) external {}

    function liquidate(
        address user,
        address tokenAddress,
        uint256 amount
    ) external {}

    function checkLT(
        address tokenAddress,
        uint256 amount
    ) internal view returns (bool) {
        uint256 LT = ((_reserve[msg.sender][tokenAddress] - amount) *
            dreamOracle.getPrice(tokenAddress) *
            liquidThreshold) / 100;
        if (LT >= _totalBorrowed[msg.sender]) {
            return true;
        }
        return false;
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        require(checkLT(tokenAddress, amount));
        uint256 blockDist = (block.number - _borrwedTime[msg.sender]);
        console.log("time : ", blockDist);
        uint256 interestRate;
        interestRate = getBorrowed();

        if (interestRate > 0) {
            if (blockDist >= 500) {
                while (blockDist > 0) {
                    blockDist -= 500;
                    interestRate =
                        ((interestRate * (1000069412154265))) /
                        (1000000000000000);
                }
            } else {
                interestRate =
                    ((interestRate * INTEREST_RATE ** blockDist)) /
                    (INTEREST_RATE2 ** blockDist);
            }
            console.log(
                "TMP",
                _totalBorrowed[msg.sender],
                interestRate,
                INTEREST_RATE ** blockDist
            );

            require(
                ((100 * interestRate) /
                    (getReserve() -
                        (amount * dreamOracle.getPrice(tokenAddress)) /
                        1e18) <
                    liquidThreshold),
                "error"
            );
        } else {
            require(_reserve[msg.sender][tokenAddress] >= amount);
        }
        payable(msg.sender).call{value: amount}("");
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
