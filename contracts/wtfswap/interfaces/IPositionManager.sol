// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IPositionManager is IERC721 {
    struct PositionInfo {
        address owner;
        address token0;
        address token1;
        uint32 index;
        uint24 fee;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint256 tokenOwner0;
        uint256 tokenOwner1;
        //feeGrowthInside0lastX128和feeGrowthInside1lastX128用于计算手续费
        uint256 feeGrowthInside0lastX128;
        uint256 feeGrowthInside1lastX128;
    }

    function GetallPositions()
        external
        view
        returns (PositionInfo[] memory positionsInfo);

    function GetPositionInfo(
        uint256 positionId
    ) external view returns (PositionInfo memory positionInfo);

    struct MintParams {
        address token0;
        address token1;
        uint32 index;
        uint256 amount0Desired;
        uint256 amount1Desired;
        address recipient;
        uint256 deadline;
    }

    function Mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 positionId,
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1
        );
    //销毁流动性
    function burn(
        uint256 positionId
    ) external returns(uint256 amount0,uint256 amount1);
    //提取手续费
    function collect(
        uint256 positionId,
        address recipient

    ) external returns(uint256 amount0,uint256 amount1);
    function mintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    )external;
}
