# K-of-N Multisig Wallet

A secure, gas-optimized implementation of a k-of-n multisignature wallet smart contract system.

## Infrastructure Setup

This repository is structured to support:
- **Hardhat** for compilation, testing, and local development
- **Foundry** for additional fuzzing, gas checks, and advanced testing
- **Solhint** and **Prettier** for linting and formatting
- **GitHub Actions** for continuous integration

### Quick Start

1. **Install PNPM and Node.js**
   Ensure you have Node.js v20+ and pnpm v9+ installed.

2. **Install Dependencies**
   ```bash
   pnpm install
   ```

3. **Compile via Hardhat**
   ```bash
   pnpm compile
   ```

4. **Run Tests**
   ```bash
   # Hardhat tests
   pnpm test:hardhat

   # Foundry tests
   pnpm test:foundry
   ```

5. **Lint & Format**
   ```bash
   pnpm lint:sol
   pnpm format
   ```

6. **CI/CD**
   Push or open a PR to trigger the GitHub Actions workflow in `.github/workflows/ci.yml`.

Additional documentation resides under `docs/`.
Refer to `contracts/src/` for contract implementations (to be added in subsequent issues).

## Project Status

- [x] Infrastructure & basic environment (Issue #1)
- [ ] Core contract architecture
- [ ] Transaction execution
- [ ] Signer management
- [ ] Comprehensive test suite
- [ ] Security analysis & formal verification

## License

MIT License. See [LICENSE](./LICENSE) for details.