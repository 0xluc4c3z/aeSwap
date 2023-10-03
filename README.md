## aestheticswap

Page: https://aestheticswap.vercel.app/

Contracts:
- swapFactory: https://goerli.etherscan.io/address/0xe46f797d2eaaf96f3a8b8fcf82473b06ef9b42c0#code
- swapRouter: https://goerli.etherscan.io/address/0xe6dffcb72444ba28a50cdd99d8b6437246b1b047#code
- pairDaiUsdt: https://goerli.etherscan.io/address/0x930C0050d6427c457Dc30bD080e0eBf37ac53686

(only functional in the goerli network)

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
