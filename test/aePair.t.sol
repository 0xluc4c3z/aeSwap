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
  address public alice = address(128);
  address public bob = address(256);

  address public pair1;
  uint256 public constant AMOUNT = 5000;

  function setUp() public {
    aefactory = new aeFactory();
    mockToken1 = new MockToken("TestToken1", "TT1", 18, admin);
    mockToken2 = new MockToken("TestToken2", "TT2", 18, admin);

    vm.startPrank(admin);
    mockToken1.transfer(alice, AMOUNT);
    mockToken2.transfer(alice, AMOUNT);
    mockToken1.transfer(bob, 3500);
    vm.stopPrank();

    pair1 = aefactory.createPair(address(mockToken1), address(mockToken2));

    aepair = aePair(pair1);
  }

  function testMint() public {
    assertEq(mockToken1.balanceOf(alice), 5000);
    assertEq(mockToken2.balanceOf(alice), 5000);

    vm.startPrank(alice);
    mockToken1.transfer(pair1, AMOUNT);
    mockToken2.transfer(pair1, AMOUNT);

    aepair.mint(alice);
    
    assertEq(aepair.balanceOf(alice), 4000);
    assertEq(aepair.totalSupply(), 5000);
    assertEq(mockToken1.balanceOf(alice), 0);
    assertEq(mockToken2.balanceOf(alice), 0);

    vm.stopPrank();
  }

  function testSwap() public {
    testMint();

    assertEq(mockToken1.balanceOf(bob), 3500);
    assertEq(mockToken2.balanceOf(bob), 0); 

    vm.startPrank(bob);
    mockToken1.transfer(pair1, 3500);

    aepair.swap(0, 2000, bob, "");

    assertEq(mockToken1.balanceOf(bob), 0);
    assertEq(mockToken2.balanceOf(bob), 2000);
    assertEq(mockToken1.balanceOf(pair1), 8500);
    assertEq(mockToken2.balanceOf(pair1), 3000);

    vm.stopPrank();
  }

  function testBurn() public {
    testSwap();

    assertEq(mockToken1.balanceOf(alice), 0);
    assertEq(mockToken2.balanceOf(alice), 0);
    assertEq(aepair.balanceOf(alice), 4000);

    assertEq(mockToken1.balanceOf(pair1), 8500);
    assertEq(mockToken2.balanceOf(pair1), 3000);

    vm.startPrank(alice);
    aepair.transfer(pair1, 4000);

    aepair.burn(alice);

    assertEq(mockToken1.balanceOf(alice), 6800);
    assertEq(mockToken2.balanceOf(alice), 2400);
    assertEq(aepair.balanceOf(alice), 0);

    assertEq(mockToken1.balanceOf(pair1), 1700);
    assertEq(mockToken2.balanceOf(pair1), 600);
  }
}