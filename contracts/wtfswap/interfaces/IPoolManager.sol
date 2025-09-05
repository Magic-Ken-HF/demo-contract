// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;
import "./IFactory.sol";

interface IpoolManager is IFactory {
    //交易池
    struct PoolInfo{
        address token0;
        address token1;
        uint32 index;
        uint8  feeProtocol;
        int24 tickLower;
        int24 tickUpper;
        int24 tick;
        uint160 sqrtPriceX96;
        uint128 liquidity;
    }
    //交易对
    struct Pair{
        address token0;
        address token1;
    }
    //获取所有交易对
    function getPairs() external view returns (Pair[] memory);
    //获取所有交易池
    function getAllPools() external view returns (PoolInfo[] memory poolsInfo);
    struct CreateAndInitializeParams{
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
    }
    //创建交易池
    function CreateAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable returns (address pool);
    
} 