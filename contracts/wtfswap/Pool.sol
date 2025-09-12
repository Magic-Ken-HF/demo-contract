// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";

contract Pool is IPool {
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
    mapping(address=>Position) public positions;

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
    //添加流动性
    function mint(
        address recipient,
        uint256 amount,
        bytes calldata data
        ) external override returns (uint256 amount0,uint256 amount1){
            // 基于 amount 计算出当前需要多少 amount0 和 amount1
        // TODO 当前先写个假的
        (amount0,amount1)=(amount/2,amount/2);
        // 把流动性记录到对应的 position 中
        position[recipient].liquidity+=amount;
        IMintCallback(recipient).mintCallback(amount0,amount1,data);

    }
    function collect(
        address recipient
        ) external override returns(uint128 amount0,uint128 amount1){
            //获取当前用户的position
            Position storage position=positions[recipient];
            position.tokensOwed0+=amount0;
            position.tokensOwed1+=amount1;

    }
    //移除流动性
    function burn(
        uint128 amount
        ) external override returns(uint256 amount0,uint256 amount1){

    }
    //交易
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {}
}