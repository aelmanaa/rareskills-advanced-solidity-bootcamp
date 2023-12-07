# Solidity Contract Examples

This repository contains a series of Solidity smart contracts designed to address specific functionalities and security concerns in the context of ERC20 tokens and smart contract interactions.

## Directory Structure

```
src
├── 1.sanctions
│   └── SanctionedToken.sol
├── 2.godmode
│   └── TokenGodMode.sol
├── 3.tokensale
│   └── TokenSale.sol
└── 4.untrusted-escrow
    └── UntrustedEscrow.sol
```

Each contract in the `src` directory provides a solution to the following challenges:

- [x] **Solidity Contract 1:** `SanctionedToken.sol` implements a fungible token with functionality allowing an admin to ban specified addresses from sending and receiving tokens, addressing the need for enforceable sanctions within the token ecosystem.

- [x] **Solidity Contract 2:** `TokenGodMode.sol` grants a special address the ability to transfer tokens between any addresses, effectively acting as a 'god mode' within the token's operational parameters.

- [x] **Solidity Contract 3:** `TokenSale.sol` tackles the complex challenge of a token sale with a bonding curve, where the price of tokens increases linearly as more are purchased. This contract also considers potential sandwich attacks and implements strategies to mitigate them.

- [x] **Solidity Contract 4:** `UntrustedEscrow.sol` creates a secure escrow mechanism for arbitrary ERC20 tokens, allowing a seller to withdraw tokens after a 3-day holding period. The contract is designed to defend against common security issues and is capable of handling fee-on-transfer tokens and non-standard ERC20 tokens, ensuring broader compatibility and safety.

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
