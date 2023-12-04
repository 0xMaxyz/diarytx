require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-network-helpers");
require("dotenv").config();

const POLYGON_RPC = process.env.POLYGON_RPC_URL;
const PRV_KEY = process.env.PRIVATEKEY;
const MUMBAI_RPC = process.env.MUMBAI_RPC_URL;

module.exports = {
    solidity: "0.8.20",
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
        },
        polygon: {
            chainId: 137,
            url: POLYGON_RPC,
            accounts: [PRV_KEY],
        },
        mumbai_testnet: {
            chainId: 80001,
            url: MUMBAI_RPC,
            accounts: [PRV_KEY],
        },
    },
    gasReporter: {
        enabled: true,
        currency: "ETH",
        outputFile: "gas-report.txt",
        noColors: true,
    },
    contractSizer: {
        runOnCompile: false,
        only: ["Diary"],
    },
    namedAccounts: {
        deployer: {
            default: 0,
            localhost: 0,
            polygon: 0,
            mumbai_testnet: 0,
        },
        user1: {
            default: 1,
            localhost: 1,
            polygon: 1,
            mumbai_testnet: 1,
        },
        user2: {
            default: 2,
            localhost: 2,
            polygon: 2,
            mumbai_testnet: 2,
        },
    },
};

