const { network } = require("ethers");
const networkConfig = {
    default: {
        name: "hardhat",
    },
    31337: {
        name: "loclhost",
    },
};
const developmentChains = ["hardhat", "localhost"];

module.exports = {
    networkConfig,
    developmentChains,
};
