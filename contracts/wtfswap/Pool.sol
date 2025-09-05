// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";

contract Pool is IPool{} {
    /// @inheritdoc IPool
    address public immutable override factory;
    /// @inheritdoc IPool
    address public immutable override token0;
    /// @inheritdoc IPool
    address public immutable override token1;
    /// @inheritdoc IPool
    uint24 public immutable override fee;
    /// @inheritdoc IPool
    int24 public immutable override tickLower;
    /// @inheritdoc IPool
    int24 public immutable override tickUpper;

    /// @inheritdoc IPool
    uint160 public override sqrtPriceX96;
    /// @inheritdoc IPool
    int24 public override tick;
    /// @inheritdoc IPool
    uint128 public override liquidity;

    // 用一个 mapping 来存放所有 Position 的信息
    mapping (address => Position) public position;

    constructor(){
        // constructor 中初始化 immutable 的常量。
        // Factory 创建 Pool 时会通 new Pool{salt: salt}() 的方式创建 Pool 合约，
        //通过 salt 指定 Pool 的地址，这样其他地方也可以推算出 Pool 的地址。
        // 参数通过读取 Factory 合约的 parameters 获取。
        // 不通过构造函数传入，因为 CREATE2 会根据 initcode 
        //计算出新地址（new_address = hash(0xFF, sender, salt, bytecode)），
        //带上参数就不能计算出稳定的地址了。
        (factory,token0,token1,fee,tickLower,tickUpper)=IFactory(
            msg.sender
        ).parameters();
    }
    function initialize(uint160 sqrtPriceX96_) external override{
        sqrtPriceX96 = sqrtPriceX96_;
    }
    function mint(
        address recipient,
        uint256 amount,
        bytes calldata data
        ) external override returns (uint256 amount0,uint256 amount1){
            

    }
}