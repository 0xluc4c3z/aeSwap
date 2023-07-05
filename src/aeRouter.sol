// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.19;

import './interfaces/IaeRouter.sol';
import './interfaces/IaeFactory.sol';
import './interfaces/IaePair.sol';
import './interfaces/IWETH.sol';
import './libraries/aeLibrary.sol';
import './types/DataTypes.sol';
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

contract aeRouter is IaeRouter {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    address public override immutable factory;
    address public override immutable WETH;

    modifier ensure(uint256 deadline) {
        if(deadline < block.timestamp) revert Expired();
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        if(msg.sender != WETH) revert OnlyWETH();
    }

    function _addLiquidity(
        DataTypes.ExecuteLiquidityParams memory params
    ) private returns (uint256 amountA, uint256 amountB) {
        if (IaeFactory(factory).getPair(params.tokenA, params.tokenB) == address(0)) {
            IaeFactory(factory).createPair(params.tokenA, params.tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = aeLibrary.getReserves(factory, params.tokenA, params.tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (params.amountADesired, params.amountBDesired);
        } else {
            uint256 amountBOptimal = aeLibrary.quote(params.amountADesired, reserveA, reserveB);
            if (amountBOptimal <= params.amountBDesired) {
                if (amountBOptimal < params.amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (params.amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = aeLibrary.quote(params.amountBDesired, reserveB, reserveA);
                if (amountAOptimal > params.amountADesired) revert InsufficientAAmount();
                if (amountAOptimal < params.amountAMin) revert InsufficientAAmount(); 
                (amountA, amountB) = (amountAOptimal, params.amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(
            DataTypes.ExecuteLiquidityParams({
                tokenA: tokenA,
                tokenB: tokenB,
                amountADesired: amountADesired,
                amountBDesired: amountBDesired,
                amountAMin: amountAMin,
                amountBMin: amountBMin
            })
        );
        address pair = aeLibrary.pairFor(factory, tokenA, tokenB);
        ERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        ERC20(tokenB).transferFrom(msg.sender, pair, amountB);
        liquidity = IaePair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            DataTypes.ExecuteLiquidityParams({
                tokenA: token,
                tokenB: WETH,
                amountADesired: amountTokenDesired,
                amountBDesired: msg.value,
                amountAMin: amountTokenMin,
                amountBMin: amountETHMin
            })
        );
        address pair = aeLibrary.pairFor(factory, token, WETH);
        ERC20(token).transferFrom(msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        if (!IWETH(WETH).transfer(pair, amountETH)) revert TransferFail(); 
        liquidity = IaePair(pair).mint(to);
        if (msg.value > amountETH) msg.sender.safeTransferETH(msg.value - amountETH); // refund dust eth, if any
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = aeLibrary.pairFor(factory, tokenA, tokenB);
        ERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IaePair(pair).burn(to);
        (address token0,) = aeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientAAmount();
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        ERC20(token).safeTransfer(to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        to.safeTransferETH(amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address pair = aeLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? (type(uint256).max - 1) : liquidity;
        ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address pair = aeLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? (type(uint256).max - 1) : liquidity;
        ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    function _swap(uint256[] memory amounts, address[] memory path, address _to) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = aeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? aeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IaePair(aeLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = aeLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        ERC20(path[0]).safeTransferFrom(msg.sender, aeLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = aeLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] >amountInMax) revert ExcessiveInputAmount();
        ERC20(path[0]).safeTransferFrom(msg.sender, aeLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) revert InvalidPath();
        amounts = aeLibrary.getAmountsOut(factory, msg.value, path);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        IWETH(WETH).deposit{value: amounts[0]}();
        if (!IWETH(WETH).transfer(aeLibrary.pairFor(factory, path[0], path[1]), amounts[0])) revert TransferFail();
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[path.length - 1] != WETH) revert InvalidPath();
        amounts = aeLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) revert ExcessiveInputAmount();
        ERC20(path[0]).safeTransferFrom(msg.sender, aeLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        to.safeTransferETH(amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[path.length - 1] != WETH) revert InvalidPath();
        amounts = aeLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        ERC20(path[0]).safeTransferFrom(msg.sender, aeLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        to.safeTransferETH(amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[path.length - 1] != WETH) revert InvalidPath();
        amounts = aeLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > msg.value) revert ExcessiveInputAmount();
        IWETH(WETH).deposit{value: amounts[0]}();
        if (!IWETH(WETH).transfer(aeLibrary.pairFor(factory, path[0], path[1]), amounts[0])) revert TransferFail();
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) msg.sender.safeTransferETH(msg.value - amounts[0]); // refund dust eth, if any
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure override returns (uint256 amountB) {
        return aeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure override returns (uint256 amountOut) {
        return aeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) public pure override returns (uint256 amountIn) {
        return aeLibrary.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) public view override returns (uint256[] memory amounts) {
        return aeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) public view override returns (uint256[] memory amounts) {
        return aeLibrary.getAmountsIn(factory, amountOut, path);
    }
}