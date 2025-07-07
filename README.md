# SimpleDEX

A simple decentralized exchange (DEX) smart contract project for educational purposes. This project demonstrates the core mechanics of an automated market maker (AMM) DEX, including liquidity provision, token swaps, and LP token logic, using Solidity.

## Features
- Add and remove liquidity for two ERC-20 tokens (TokenA and TokenB)
- Swap between TokenA and TokenB using the constant product formula
- LP token logic for tracking liquidity provider shares
- Custom errors for gas-efficient error handling
- Events for all major actions (liquidity, swaps)
- Input validation and reentrancy protection

## Requirements
- Solidity ^0.8.0
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) (installed via npm for local development)
- [Remix IDE](https://remix.ethereum.org/) (recommended for quick deployment and testing)
- Node.js and npm (for local development)

## Setup

### Option 1: Using Remix (Recommended for Quick Start)
1. Open [Remix IDE](https://remix.ethereum.org/).
2. Upload the contract files (`SimpleDEX.sol`, `TokenA.sol`, `TokenB.sol`).
3. Compile the contracts in Remix.
4. Deploy `TokenA` and `TokenB` with your desired initial supply (in wei, e.g., `1000 * 1e18`).
5. Deploy `SimpleDEX` with the addresses of TokenA and TokenB.
6. Use Remix to interact with the contracts for adding/removing liquidity and swapping tokens.

### Option 2: Local Development (Node.js + npm)
1. Clone the repository:
   ```sh
   git clone <your-repo-url>
   cd liquidity-pool
   ```
2. Install dependencies:
   ```sh
   npm install
   ```
3. Use your preferred local development tool (e.g., Hardhat, Foundry, Truffle) to compile, deploy, and test the contracts.
   - Contracts import OpenZeppelin from `node_modules`.
   - Example (with Hardhat):
     ```sh
     npx hardhat compile
     npx hardhat test
     ```


## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Note:** This project is for educational and demonstration purposes only. Do not use in production or with real funds. 