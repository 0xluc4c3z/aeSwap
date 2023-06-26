// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.19;

import './interfaces/IaePair.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import 'solmate/src/tokens/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import 'solmate/src/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import './libraries/UQ112x112.sol';
import './interfaces/IaeCallee.sol';

contract aePair is ERC20, IaePair, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event


    constructor() ERC20('aeToken', 'ae', 18) {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) revert Forbidden(); // sufficient check
        
        token0 = _token0;
        token1 = _token1;
    }

    
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); 
        } else {
            liquidity = Math.min(
                (amount0 *_totalSupply) / _reserve0, 
                (amount1 * _totalSupply) / _reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Mint(msg.sender, amount0, amount1);
    }

    
    function burn(address to) 
        external nonReentrant 
        returns (uint256 amount0, uint256 amount1) 
    {
        address _token0 = token0;                               
        address _token1 = token1;                    

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; 
        amount0 = liquidity * balance0 / _totalSupply; 
        amount1 = liquidity * balance1 / _totalSupply; 

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        IERC20(_token0).safeTransfer(to, amount0);
        IERC20(_token1).safeTransfer(to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out, 
        uint256 amount1Out, 
        address to, 
        bytes calldata data
    ) external nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) 
            revert InsufficientOutputAmount();

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 

        if (amount0Out > _reserve0 || amount1Out > _reserve1) 
            revert InsufficientLiquidity();

        if (to == token0 || to == token1) revert InvalidTo();

        if (amount0Out > 0) IERC20(token0).safeTransfer(to, amount0Out); 
        if (amount1Out > 0) IERC20(token1).safeTransfer(to, amount1Out); 
        if (data.length > 0) 
            IaeCallee(to).aeCall(
                msg.sender, 
                amount0Out, 
                amount1Out, 
                data
            );

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
       
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out) 
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out 
            ? balance1 - (_reserve1 - amount1Out) 
            : 0;

        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        if (
            balance0Adjusted * balance1Adjusted <
            uint256(_reserve0) * uint256(_reserve1) * (1000**2)
        ) revert InvalidK();
        

        _update(balance0, balance1, _reserve0, _reserve1);
        
        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        IERC20(_token0).safeTransfer(to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        IERC20(_token1).safeTransfer(to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    
    function sync() external nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this)), 
            reserve0, 
            reserve1
        );
    }

    function getReserves() 
        public 
        view 
        returns (
            uint112, 
            uint112, 
            uint32
        ) 
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0, 
        uint256 balance1, 
        uint112 _reserve0, 
        uint112 _reserve1
    ) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) 
            revert Overflow();

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        unchecked{
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; 
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += 
                uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * 
                timeElapsed; 
            price1CumulativeLast += 
                uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * 
                timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }
}