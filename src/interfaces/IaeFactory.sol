// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.19;

interface IaeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    error IdenticAddresses();
    error ZeroAddress();
    error PairExists();

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}