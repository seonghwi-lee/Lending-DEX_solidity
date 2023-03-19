// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CustomERC20} from "../test/Dex.t.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    IERC20 private tokenX;
    IERC20 private tokenY;

    address private owner;
    mapping(address => uint) balances;
    uint256 rootK; // equal to liquidity
    uint256 reservedX;
    uint256 reservedY;
    uint256 _amountX;
    uint256 _amountY;

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
        rootK = sqrt(reservedX * reservedY);
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

        if (reservedX == 0 && reservedY == 0) {
            setReserve(_amountX, _amountY);
        }

        uint256 reward;
        uint256 optToken = quote(tokenXAmount);
        if (optToken > tokenYAmount) {
            optToken = quote(tokenYAmount);
            require(optToken == tokenXAmount);
            tokenX.transferFrom(msg.sender, address(this), optToken);
            tokenY.transferFrom(msg.sender, address(this), tokenYAmount);
            reward = sqrt(optToken * tokenYAmount);
        } else {
            require(optToken == tokenYAmount);
            tokenX.transferFrom(msg.sender, address(this), tokenXAmount);
            tokenY.transferFrom(msg.sender, address(this), optToken);
            reward = sqrt(optToken * tokenXAmount);
        }

        if (minimumLPTokenAmount > reward) revert();
        return reward;
    }

    function removeLiquidity(
        uint256 LPTokenAmount,
        uint256 minimumTokenXAmount,
        uint256 minimumTokenYAmount
    ) external returns (uint256 _tx, uint256 _ty) {
        require(LPTokenAmount != 0);

        setReserve();
        uint256 amountX = rootK / reservedX;
        uint256 amountY = rootK / reservedY;

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
