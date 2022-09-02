require('dotenv').config()
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
np
  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  
    defaultNetwork: "matic",
    networks: {
      hardhat: {
      },
      matic: {
        url: "https://rpc-mumbai.maticvigil.com",
        accounts: [process.env.PRIVATE_KEY]
      }
    },
    etherscan: {
      apiKey: process.env.POLYGONSCAN_API_KEY
    },
  solidity:{
    version: "0.8.4",
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
}
};
