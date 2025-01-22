require("@nomicfoundation/hardhat-toolbox");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts/src",
    tests: "./test/hardhat",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  defaultNetwork: "hardhat",
  networks: {
    // local and test networks can be configured here
    hardhat: {},
    // add testnet or mainnet config later
  }
};