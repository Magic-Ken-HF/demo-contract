// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IPositionManager is IERC721{
    struct PositionInfo{
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


    }
    function GetPositionInfo(
        uint256 positionId
        ) external view returns (PositionInfo memory positionInfo);
    struct MintParams{
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
    external payable returns(
        uint256 positionId,
        uint256 liquidity,
        uint256 amount0,
        uint256 amount1
    );

}