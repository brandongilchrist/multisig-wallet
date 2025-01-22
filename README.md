# K-of-N Multisig Wallet

A secure, gas-optimized implementation of a k-of-n multisignature wallet smart contract system. This implementation requires k valid signatures from n designated signers to execute transactions, with comprehensive security features and formal verification.

## Features

- K-of-n signature requirement for transaction execution
- Secure signature validation with replay protection
- Gas-optimized implementation
- Comprehensive test coverage (Hardhat & Foundry)
- Formal verification with Certora
- Emergency pause functionality
- Timelock for critical operations
- Upgradeable design (optional)
- Full ERC20/ERC721 token support
- Protected against common attack vectors

## Security Features

- ✅ Reentrancy protection
- ✅ Signature replay prevention
- ✅ Signature malleability protection
- ✅ Front-running protection
- ✅ Integer overflow/underflow protection
- ✅ Gas griefing protection
- ✅ Formal verification
- ✅ Comprehensive security testing

## Prerequisites

- Node.js v20.11.0+
- pnpm v9.1.0+
- Foundry latest version
- Solidity v0.8.20+
- Python 3.9+ (for Slither)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/multisig-wallet.git
cd multisig-wallet
```

2. Install dependencies:
```bash
pnpm install
```

3. Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

4. Install Python dependencies (for security tools):
```bash
pip install slither-analyzer mythril
```

## Development Setup

1. Copy environment template:
```bash
cp .env.example .env
```

2. Configure environment variables:
```env
INFURA_API_KEY=your_infura_key
ETHERSCAN_API_KEY=your_etherscan_key
PRIVATE_KEY=your_private_key
REPORT_GAS=true
```

3. Setup pre-commit hooks:
```bash
pnpm prepare
```

## Testing

### Run All Tests
```bash
# Run both Hardhat and Foundry tests
pnpm test

# Run with gas reporting
pnpm test:gas
```

### Hardhat Tests
```bash
# Run all Hardhat tests
pnpm test:hardhat

# Run specific test file
npx hardhat test test/hardhat/MultisigWallet.test.ts
```

### Foundry Tests
```bash
# Run all Foundry tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-contract MultisigWalletTest
```

### Coverage
```bash
# Generate coverage reports
pnpm coverage

# View detailed coverage report
pnpm coverage:report
```

## Security Analysis

### Static Analysis
```bash
# Run Slither
pnpm security:slither

# Run Mythril
pnpm security:mythril
```

### Formal Verification
```bash
# Run Certora verification
pnpm verify:certora
```

## Deployment

1. Compile contracts:
```bash
# Compile with both Hardhat and Foundry
pnpm compile
```

2. Deploy:
```bash
# Deploy to local network
pnpm deploy:local

# Deploy to testnet
pnpm deploy:testnet

# Deploy to mainnet
pnpm deploy:mainnet
```

## Contract Verification

```bash
# Verify on Etherscan
pnpm verify:etherscan

# Verify on Sourcify
pnpm verify:sourcify
```

## Documentation

### Generate Documentation
```bash
# Generate NatSpec documentation
pnpm docs:generate
```

### View Gas Report
```bash
# Generate gas report
pnpm gas-report
```

## Project Structure

```
contracts/
├── src/
│   ├── core/           # Core contract implementations
│   ├── interfaces/     # Contract interfaces
│   ├── libraries/      # Shared libraries
│   └── test/          # Mock contracts for testing
scripts/
├── deploy/            # Deployment scripts
└── verify/           # Verification scripts
test/
├── hardhat/          # Hardhat TypeScript tests
│   ├── unit/         # Unit tests
│   └── integration/  # Integration tests
└── foundry/          # Foundry Solidity tests
    ├── unit/         # Unit tests
    ├── fuzz/         # Fuzzing tests
    └── invariant/    # Invariant tests
certora/
├── specs/            # Formal verification specs
└── scripts/         # Verification scripts
```

## Available Scripts

- `pnpm compile`: Compile all contracts
- `pnpm test`: Run all tests
- `pnpm test:gas`: Run tests with gas reporting
- `pnpm coverage`: Generate coverage reports
- `pnpm format`: Format code with Prettier
- `pnpm lint`: Lint code with ESLint
- `pnpm security`: Run all security tools
- `pnpm deploy`: Deploy contracts
- `pnpm verify`: Verify contracts
- `pnpm docs`: Generate documentation

## Contributing

1. Ensure you have read the [CONTRIBUTING.md](CONTRIBUTING.md)
2. Fork the repository
3. Create your feature branch: `git checkout -b feature/amazing-feature`
4. Run tests: `pnpm test`
5. Commit your changes: `git commit -m 'feat: add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a pull request

## Security

### Audit Status

This project has undergone security audits by:
- [Audit Firm 1] - [Date]
- [Audit Firm 2] - [Date]

### Bug Bounty

Please review our [Security Policy](SECURITY.md) for details about our bug bounty program.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please visit the [Discussions](https://github.com/your-username/multisig-wallet/discussions) tab.

## Gas Optimizations

Please refer to [GAS_OPTIMIZATIONS.md](docs/GAS_OPTIMIZATIONS.md) for a detailed breakdown of gas optimization strategies used in this project.

## Security Considerations

Please refer to [SECURITY_CONSIDERATIONS.md](docs/SECURITY_CONSIDERATIONS.md) for a comprehensive review of security measures implemented in this project.

## Acknowledgements

- OpenZeppelin Contracts
- Foundry
- Hardhat
- Certora Prover
- Slither
- Mythril