// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.19;

library DataTypes {


    struct ExecuteLiquidityParams {
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
    }
}