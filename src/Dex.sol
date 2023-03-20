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
    uint256 feeRate;

    constructor(address _tokenX, address _tokenY) {
        owner = msg.sender;
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
        feeRate = 1000;
    }

    function swap(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 tokenMinimumOutputAmount
    ) external returns (uint256 outputAmount) {
        require(tokenXAmount == 0 || tokenYAmount == 0);
        uint256 tokenFrom;
        uint256 tokenTo;
        (tokenFrom, tokenTo) = (tokenXAmount == 0)
            ? (tokenYAmount, tokenXAmount)
            : (tokenXAmount, tokenYAmount);

        setReserve();

        if (tokenXAmount == 0) {
            tokenY.transferFrom(msg.sender, address(this), tokenFrom);
            outputAmount = uint256(
                -(int(reservedY * reservedX) / int(reservedY + tokenFrom)) +
                    int(reservedX)
            );
        } else {
            tokenX.transferFrom(msg.sender, address(this), tokenFrom);
            outputAmount = uint256(
                -(int(reservedX * reservedY) / int(reservedX + tokenFrom)) +
                    int(reservedY)
            );
        }

        setReserve();
        outputAmount = (outputAmount * (feeRate - 1)) / feeRate;

        console.log("tokenX: ", tokenX.balanceOf(address(this)));
        console.log("tokenY: ", tokenY.balanceOf(address(this)));
        // console.log("tokenFrom", tokenFrom);
        // console.log("outputAmount", outputAmount);
        console.log();

        if (tokenXAmount == 0) {
            tokenX.transfer(msg.sender, outputAmount);
        } else {
            tokenY.transfer(msg.sender, outputAmount);
        }
        setReserve();

        require(outputAmount >= tokenMinimumOutputAmount);
    }

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
        rootK = sqrt(reservedX * reservedY);
    }

    function setReserve() internal {
        setReserve(0, 0);
    }

    function quote(
        uint256 amountX,
        uint256 _reservedX,
        uint256 _reservedY
    ) internal returns (uint256 amountY) {
        require(amountX > 0);
        require(_reservedX > 0 && _reservedY > 0);

        amountY = (amountX * _reservedY) / _reservedX;
    }

    function addLiquidity(
        uint256 tokenXAmount,
        uint256 tokenYAmount,
        uint256 minimumLPTokenAmount
    ) external returns (uint256 LPTokenAmount) {
        require(tokenXAmount > 0 && tokenYAmount > 0);
        setReserve(tokenXAmount, tokenYAmount);

        uint256 reward;
        uint256 optToken = quote(curX, reservedX, reservedY);
        if (optToken > curY) {
            optToken = quote(curY, reservedY, reservedX);
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

        setReserve();

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
        uint256 n = 10 ** 5;
        uint256 users = (totalReward * n) / LPTokenAmount;

        if (users % 10 != 0) {
            users = totalReward / LPTokenAmount;
            n = 1;
        }

        setReserve();
        uint256 amountX = (reservedX / users) * n;
        uint256 amountY = (reservedY / users) * n;
        require(
            minimumTokenXAmount <= amountX && minimumTokenYAmount <= amountY
        );

        reservedX -= amountX;
        reservedY -= amountY;

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
