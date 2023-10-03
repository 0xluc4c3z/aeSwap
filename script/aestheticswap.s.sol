// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/aeFactory.sol";
import "../src/aeRouter.sol";

contract aestheticswapScript is Script {
  function setUp() public {}

  function run() public {
    uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");
    address account = vm.addr(privateKey);

    address weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    vm.startBroadcast(privateKey);

    aeFactory aefactory = new aeFactory();
    aeRouter aerouter = new aeRouter(address(aefactory), weth);

    vm.stopBroadcast();
  }
}