const Creature = artifacts.require("./Creature.sol");
const CreatureFactory = artifacts.require("./CreatureFactory.sol");

// If you want to hardcode what deploys, comment out process.env.X and use
// true/false;
const DEPLOY_ALL = process.env.DEPLOY_ALL;
const DEPLOY_CREATURES_SALE = process.env.DEPLOY_CREATURES_SALE || DEPLOY_ALL;
// Note that we will default to this unless DEPLOY_ACCESSORIES is set.
// This is to keep the historical behavior of this migration.
const DEPLOY_CREATURES = process.env.DEPLOY_CREATURES || DEPLOY_ALL;

module.exports = async (deployer, network, addresses) => {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress = "";
  if (network === "rinkeby") {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  if (DEPLOY_CREATURES) {
    await deployer.deploy(
      Creature,
      "My Creature test",
      "MCT",
      "https://creatures-api.opensea.io/api/creature/",
      "https://creatures-api.opensea.io/contract/opensea-creatures",
      proxyRegistryAddress,
      { gas: 5000000 }
    );
  }

  if (DEPLOY_CREATURES_SALE) {
    await deployer.deploy(
      CreatureFactory,
      proxyRegistryAddress,
      Creature.address,
      { gas: 7000000 }
    );
    const creature = await Creature.deployed();
    await creature.grantMinterRole(CreatureFactory.address);
  }
};
