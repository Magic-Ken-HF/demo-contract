// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";
import "./libraries/SqrtPriceMath.sol";
import "./libraries/TickMath.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/LowGasSafeMath.sol";
import "./libraries/TransferHelper.sol";

contract Pool is IPool {
    using LowGasSafeMath for uint256;
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
    //记录lp的流动性信息
    struct Position {
        uint128 liquidity; //流动性
        uint128 tokensOwed0; //用户可领取的token0
        uint128 tokensOwed1; //用户可领取的token1
    }
    // 用一个 mapping 来存放所有 Position 的信息
    mapping(address => Position) public positions;

    constructor() {
        // constructor 中初始化 immutable 的常量。
        // Factory 创建 Pool 时会通 new Pool{salt: salt}() 的方式创建 Pool 合约，
        //通过 salt 指定 Pool 的地址，这样其他地方也可以推算出 Pool 的地址。
        // 参数通过读取 Factory 合约的 parameters 获取。
        // 不通过构造函数传入，因为 CREATE2 会根据 initcode
        //计算出新地址（new_address = hash(0xFF, sender, salt, bytecode)），
        //带上参数就不能计算出稳定的地址了。
        (factory, token0, token1, tickLower, tickUpper,fee) = IFactory(
            msg.sender
        ).parameters();
    }

    function initialize(uint160 sqrtPriceX96_) external override {
        sqrtPriceX96 = sqrtPriceX96_;
    }

    //添加流动性
    /*传入要添加的流动性amount以及data,这个data是用来在回调函数中传递参数的。recipent可以指定将流动性的权益赋给谁
      要注意的是amount是流动性，而不是要mint的代币。需要基于传入的amount计算amount0和amount1的，并返回这两个值。
      amount0是和amount1是分别是两个代币的数量，另外还需要再mint方法中调用我们定义的回调函数mintCallback,以及修改
      合约中的一些状态。
     */
    function mint(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(amount>0,"Mint amount must be greater than 0!");
        // 基于 amount 计算出当前需要多少 amount0 和 amount1
        (int256 amount0Int,int256 amount1Int)=_modifyPosition(
            ModifyPositionParam(
                {
                    owner:recipient,
                    liquidityDelta:int128(amount)
                }
            )
        );
        amount0=uint256(amount0Int);
        amount1=uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;
        if(amount0>0) balance0Before =balance0();
        if(amount1>0) balance1Before =balance1();

        // 把流动性记录到对应的 position 中
        IMintCallback(msg.sender).mintCallback(amount0, amount1, data);
        if(amount0>0) require(balance0Before.add(amount0) <= balance0(),"M0");
        
        if(amount1>0) require(balance1Before.add(amount1) <= balance1(),"M1");

        emit Mint(msg.sender,recipient,amount,amount0,amount1);
    }
    function balance0()private view  returns (uint256) {
        (bool success,bytes memory data)=token0.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector,address(this))
        );
        require (success && data.length>=32);
        return abi.decode(data,(uint256));
    }
    function balance1()private view  returns (uint256) 
    {
        (bool success,bytes memory data)=token1.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector,address(this))
        );
        require (success && data.length>=32);
        return abi.decode(data,(uint256));
        
    }
    struct ModifyPositionParam{
        address owner;
        int128 liquidityDelta;

    }
    //通过流动性计算amount0和amount1
    function _modifyPosition(
        ModifyPositionParam memory params
    ) private returns (int256 amount0,int256 amount1) {
        //通过新增的流动性计算amount0和amount1
        amount0 =SqrtPriceMath.getAmount0Delta(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickUpper),
            params.liquidityDelta
        );
        amount1 =SqrtPriceMath.getAmount1Delta(
            TickMath.getSqrtPriceAtTick(tickLower),
            sqrtPriceX96,
            params.liquidityDelta
        );
        Position storage position =positions[params.owner];
        position.liquidity= LiquidityMath.addDelta(liquidity,params.liquidityDelta);

        position.liquidity=LiquidityMath.addDelta(
            position.liquidity,
            params.liquidityDelta
        );

    }

    //移除流动性
    /*计算出要退回给LP的amount0和amount1 记录在合约状态中*/
    function burn(
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(amount>0,"Burn amount must be greater than 0!");
        require(amount<=positions[msg.sender].liquidity,"Burn amount exceeds liquidity!");
        //修改position中的信息
        (int256 amount0Int,int256 amount1Int)=_modifyPosition(
            ModifyPositionParam({
                owner : msg.sender,
                liquidityDelta:-int128(amount)
            })
        );
        amount0=uint256(-amount0Int);
        amount1=uint256(-amount1Int);
        if(amount0>0 || amount1>0){
            (
                positions[msg.sender].tokensOwed0,
                positions[msg.sender].tokensOwed1
            )=(
                positions[msg.sender].tokensOwed0+uint128(amount0),
                positions[msg.sender].tokensOwed1 +uint128(amount1)
            );

        }
        //触发事件
        emit Burn(msg.sender,amount,amount0,amount1);
    }

    //交易
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {}
    function feeGrowthGlobal0X128() external view override returns (uint256) {}

    function feeGrowthGlobal1X128() external view override returns (uint256) {}

    function getPosition(
        address owner
    )
        external
        view
        override
        returns (
            uint128 _liquidity,
            uint256 feeGrothInside0LastX128,
            uint256 feeGrothInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {}
    //提取代币
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override returns (uint128 amount0, uint128 amount1) {
        //获取当前用户的position
        Position storage position =positions[msg.sender];
        //把钱退回给用户
        amount0 =amount0Requested>position.tokensOwed0
            ?position.tokensOwed0
            :amount0Requested;
        amount1 =amount1Requested>position.tokensOwed1
            ?position.tokensOwed1
            :amount1Requested;
        if(amount0>0){
            position.tokensOwed0 -=amount0;
            TransferHelper.safeTransfer(token0,recipient,amount0);

        }
        if(amount1>0){
            position.tokensOwed1-=amount1;
            TransferHelper.safeTransfer(token1,recipient,amount1);

        }
        emit Collect(msg.sender,recipient,amount0,amount1);
    }
}