// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'solmate/src/tokens/ERC20.sol';

contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address recipient_)
        ERC20(name_, symbol_, decimals_)
    {

        _mint(recipient_, 1_000_000_100 * (10 ** decimals_));
    }
}
