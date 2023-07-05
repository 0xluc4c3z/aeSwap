// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/aeFactory.sol";
import "./utils/mock/MockToken.sol";
import "../src/aePair.sol";
import "../src/aeRouter.sol";
import "solmate/src/tokens/WETH.sol";

contract aeRouterTest is Test {
  aeFactory public aefactory;
  MockToken public mockToken1;
  MockToken public mockToken2;
  aePair public aepair;
  WETH public weth;
  aeRouter public aerouter;

  address public admin = address(64);
  address public alice = address(128);
  address public bob = address(256);

  address public pair1;
  uint256 public constant AMOUNT = 5000;

  function setUp() public {
    aefactory = new aeFactory();
    mockToken1 = new MockToken("TestToken1", "TT1", 18, admin);
    mockToken2 = new MockToken("TestToken2", "TT2", 18, admin);
    weth = new WETH();
    aerouter = new aeRouter(address(aefactory), address(weth));

    vm.startPrank(admin);
    mockToken1.transfer(alice, AMOUNT);
    mockToken2.transfer(alice, AMOUNT);
    mockToken1.transfer(bob, 3500);
    vm.stopPrank();
  } 

  function testAddLiquidity() public {
    vm.startPrank(alice);

    mockToken1.approve(address(aerouter), AMOUNT);
    mockToken2.approve(address(aerouter), AMOUNT);

    aerouter.addLiquidity(address(mockToken1), address(mockToken2), AMOUNT, AMOUNT, 0, 0, alice, type(uint256).max);

    // assertEq(mockToken1.balanceOf(alice), 0);
    // assertEq(mockToken2.balanceOf(alice), 0);
  }
    

}