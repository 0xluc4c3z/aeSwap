// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/aeFactory.sol";
import "./utils/mock/MockToken.sol";
import "../src/aePair.sol";

contract aePairTest is Test {
  aeFactory public aefactory;
  MockToken public mockToken1;
  MockToken public mockToken2;
  aePair public aepair;

  address public admin = address(64);
  address public bob = address(128);

  address public pair1;
  uint256 public constant AMOUNT = 5000;

  function setUp() public {
    aefactory = new aeFactory();
    mockToken1 = new MockToken("TestToken1", "TT1", 18, admin);
    mockToken2 = new MockToken("TestToken2", "TT2", 18, admin);

    vm.prank(admin);
    mockToken1.transfer(bob, 3500);

    pair1 = aefactory.createPair(address(mockToken1), address(mockToken2));

    aepair = aePair(pair1);
  }

  function testMint() public {
    vm.startPrank(admin);
    mockToken1.transfer(pair1, AMOUNT);
    mockToken2.transfer(pair1, AMOUNT);

    aepair.mint(admin);
    
    assertEq(aepair.balanceOf(admin), 4000);
    assertEq(aepair.totalSupply(), 5000);
    assertEq(mockToken1.balanceOf(pair1), 5000);
    assertEq(mockToken2.balanceOf(pair1), 5000);
  }

  function testSwap() public {
    testMint();

    vm.prank(bob);
    aepair.swap(amount0Out, amount1Out, to, data);
  }
}