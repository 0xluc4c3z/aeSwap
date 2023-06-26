// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/aeFactory.sol";
import "./utils/mock/MockToken.sol";

contract aeFactoryTest is Test {
  aeFactory public aefactory;
  MockToken public mockToken1;
  MockToken public mockToken2;

  address public admin = address(64);

  function setUp() public {
    aefactory = new aeFactory();
    mockToken1 = new MockToken("TestToken1", "TT1", 18, admin);
    mockToken2 = new MockToken("TestToken2", "TT2", 18, admin);
  }

  function testCreatePair() public {
    address pair1 = aefactory.createPair(address(mockToken1), address(mockToken2));

    assertEq(aefactory.allPairsLength(), 1);
    assertEq(aefactory.getPair(address(mockToken1), address(mockToken2)), pair1);
  }
}