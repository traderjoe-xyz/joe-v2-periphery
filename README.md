# [Joe V2: Liquidity Book Periphery](https://github.com/traderjoe-xyz/joe-v2-periphery)

This repository contains the periphery contracts for Liquidity Book. The contracts can be found here: [Joe V2: Liquidity Book](https://github.com/traderjoe-xyz/joe-v2)

For more information, go to the [documentation](https://docs.traderjoexyz.com/) and the [whitepaper](https://github.com/traderjoe-xyz/LB-Whitepaper/blob/main/Joe%20v2%20Liquidity%20Book%20Whitepaper.pdf).

## Install foundry

Foundry documentation can be found [here](https://book.getfoundry.sh/forge/index.html).

### On Linux and macOS

Open your terminal and type in the following command:

```
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. Then install Foundry by running:

```
foundryup
```

To update foundry after installation, simply run `foundryup` again, and it will update to the latest Foundry release.
You can also revert to a specific version of Foundry with `foundryup -v $VERSION`.

### On Windows

If you use Windows, you need to build from source to get Foundry.

Download and run `rustup-init` from [rustup.rs](https://rustup.rs/). It will start the installation in a console.

After this, run the following to build Foundry from source:

```
cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil --bins --locked
```

To update from source, run the same command again.

## Install dependencies

To install dependencies, run the following to install dependencies:

```
forge install
```

___

## Tests

To run tests, run the following command:

```
forge test
```