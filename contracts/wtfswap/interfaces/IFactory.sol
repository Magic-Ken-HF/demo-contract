// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFactory{
    struct parameters{
        address factory;
        address tokenA;
        address tokenB;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }

}