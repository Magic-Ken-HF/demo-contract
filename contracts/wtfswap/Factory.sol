// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
import "./interfaces/IFactory.sol";

abstract contract Factory is IFactory {
    address public override poolManager;
    address public override positionManager;
    address public override swapRouter;
    address public override owner;

    modifier onlyOwner(){
        require(msg.sender == owner,"FORBIDDEN");
        _;
    }
    constructor(){
        owner = msg.sender;
    }
    function setPoolManager(address _poolManager) external onlyOwner{
        poolManager = _poolManager;
    }
    function setPositionManager(address _positionManager) external onlyOwner{
        positionManager = _positionManager;
    }
    function setSwapRouter(address _swapRouter) external onlyOwner{
        swapRouter = _swapRouter;
    }
}