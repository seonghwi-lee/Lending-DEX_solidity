// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CustomERC20} from "../test/Dex.t.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "forge-std/console.sol";

contract Dex {
    IERC20 private tokenX;
    IERC20 private tokenY;

    address private owner;
    mapping(address => uint) balances;
    uint256 rootK; // equal to liquidity
    uint256 reservedX;
    uint256 reservedY;
    uint256 curX;
    uint256 curY;
    uint256 preX;
    uint256 preY;
    uint256 _amountX;
    uint256 _amountY;
    uint256 totalReward;

    constructor(address _tokenX, address _tokenY) {
        owner = msg.sender;
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
    }

    function swap(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 tokenMinimumOutputAmount
    ) external returns (uint256 outputAmount) {}

    function setReserve(uint256 amountX, uint256 amountY) internal {
        reservedX = tokenX.balanceOf(address(this)) + amountX;
        reservedY = tokenY.balanceOf(address(this)) + amountY;

        if (preX == 0 && preY == 0) {
            curX = tokenX.balanceOf(address(this)) + amountX - preX;
            curY = tokenY.balanceOf(address(this)) + amountY - preY;
        } else {
            curX = amountX;
            curY = amountY;
        }
        rootK = sqrt(curX * curY);
    }

    function setReserve() internal {
        setReserve(0, 0);
    }

    function quote(uint256 amountX) internal returns (uint256 amountB) {
        require(amountX > 0);
        require(reservedX > 0 && reservedY > 0);

        return (amountX * reservedY) / reservedX;
    }

    function addLiquidity(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 minimumLPTokenAmount
    ) external returns (uint256 LPTokenAmount) {
        require(tokenXAmount > 0 && tokenYAmount > 0);
        _amountX += tokenXAmount;
        _amountY += tokenYAmount;

        setReserve(tokenXAmount, tokenYAmount);

        uint256 reward;
        uint256 optToken = quote(curX);
        if (optToken > curY) {
            optToken = quote(curY);
            require(optToken == curX);
            tokenX.transferFrom(msg.sender, address(this), optToken);
            tokenY.transferFrom(msg.sender, address(this), tokenYAmount);
            reward = sqrt(optToken * curY);
        } else {
            require(optToken == curY);
            tokenX.transferFrom(msg.sender, address(this), tokenXAmount);
            tokenY.transferFrom(msg.sender, address(this), optToken);
            reward = sqrt(optToken * curX);
        }

        preX = tokenX.balanceOf(address(this));
        preY = tokenY.balanceOf(address(this));

        if (minimumLPTokenAmount > reward) revert();
        totalReward += reward;
        return reward;
    }

    function removeLiquidity(
        uint256 LPTokenAmount,
        uint256 minimumTokenXAmount,
        uint256 minimumTokenYAmount
    ) external returns (uint256 _tx, uint256 _ty) {
        require(LPTokenAmount != 0);
        uint256 n = 10 ** 10;
        uint256 users = (totalReward * n) / LPTokenAmount;
        if (users % 10 != 0) {
            users = totalReward / LPTokenAmount;
            n = 1;
        }
        console.log("user:", users);
        setReserve();
        uint256 amountX = (reservedX / users) * n;
        uint256 amountY = (reservedY / users) * n;
        require(
            minimumTokenXAmount <= amountX && minimumTokenYAmount <= amountY
        );

        _amountX -= amountX;
        _amountY -= amountY;

        return (amountX, amountY);
    }

    function transfer(address to, uint256 lpAmount) external returns (bool) {}

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
