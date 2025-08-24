## English README

CCIP Rebase Token (Foundry)

A lightweight Foundry project implementing a rebase-capable ERC20 token and companion Vault/Pool, with Foundry tests and scripts.

Quick index
- Contracts
  - [`RebaseToken`](src/RebaseToken.sol) — rebase-capable ERC20 implementation
  - [`RebaseTokenPool`](src/RebaseTokenPool.sol) — pool integrated with rebase logic
  - [`Vault`](src/Vault.sol) — ERC4626-style Vault adapter
  - Interface: [`interfaces/IRebaseToken.sol`](src/interfaces/IRebaseToken.sol)
- Scripts
  - [script/Deployer.s.sol](script/Deployer.s.sol)
  - [script/ConfigurePool.s.sol](script/ConfigurePool.s.sol)
  - [script/BridgeTokens.s.sol](script/BridgeTokens.s.sol)
- Tests
  - Unit tests: `test/unit/` (e.g. [test/unit/RebaseTokenTest.t.sol](test/unit/RebaseTokenTest.t.sol))
  - Integration tests: `test/integration/` (e.g. [test/integration/CrossChainTest.t.sol](test/integration/CrossChainTest.t.sol))
- Configuration
  - Foundry config: [foundry.toml](foundry.toml)
  - Remappings: [remappings.txt](remappings.txt)

Prerequisites
- Git
- Foundry (forge + cast). Install: https://getfoundry.sh

Quick start
1. Install dependencies and build:
   ```sh
   forge build
   ```
2. Run all tests (unit + integration):
   ```sh
   forge test
   ```
3. Run a script in local broadcast mode:
   ```sh
   forge script script/Deployer.s.sol:Deployer --broadcast
   ```

Project layout (summary)
- src/ — smart contract sources
  - [src/RebaseToken.sol](src/RebaseToken.sol)
  - [src/RebaseTokenPool.sol](src/RebaseTokenPool.sol)
  - [src/Vault.sol](src/Vault.sol)
  - [src/interfaces/IRebaseToken.sol](src/interfaces/IRebaseToken.sol)
- script/ — deploy & configuration scripts
  - [script/Deployer.s.sol](script/Deployer.s.sol)
  - [script/ConfigurePool.s.sol](script/ConfigurePool.s.sol)
  - [script/BridgeTokens.s.sol](script/BridgeTokens.s.sol)
- test/ — tests (unit / integration)
  - [test/unit/RebaseTokenTest.t.sol](test/unit/RebaseTokenTest.t.sol)
  - [test/unit/VaultTest.t.sol](test/unit/VaultTest.t.sol)
  - [test/integration/CrossChainTest.t.sol](test/integration/CrossChainTest.t.sol)

Contributing
Issues and PRs are welcome. Follow repository contribution guidelines (if present) and keep commits small and tested.

Other
- See repository root configuration: [foundry.toml](foundry.toml).
- For integration (cross-chain) tests, ensure any required local mocks or external services are available.

View source
- Main contract: [`src/RebaseToken.sol`](src/RebaseToken.sol)
- Vault: [`src/Vault.sol`](src/Vault.sol)
- Deployer script: [`script/Deployer.s.sol`](script/Deployer.s.sol)
