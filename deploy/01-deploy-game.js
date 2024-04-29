const { ethers, network } = require("hardhat");
const fs = require("fs").promises;

module.exports = async ({ deployments, getNamedAccounts }) => {
    const existingConfig = JSON.parse(await fs.readFile("config/deployment-config.json", "utf8"));
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    /*

    const { name, symbol, owner, initialSupply } = existingConfig[network.name].FeeToken;

    const args = [name, symbol, initialSupply, owner];

    const waitConfirmation = network.config.chainId === 31337 ? 0 : 6;

    const FeeToken = await deploy("FeeToken", {
        from: deployer,
        args,
        automine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 0 : 6
    });

    const FeeTokenAddress = FeeToken.address;

    log(`Fee Token (${network.name}) deployed to ${FeeToken.address}`);

    */

    const { blocksToAct, rollFee, rerollFee } = existingConfig[network.name].DegenTrail;

    const DegenTrail = await deploy("DegenTrail", {
        from: deployer,
        args: [blocksToAct, rollFee, rerollFee],
        automine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 0 : 6
    });

    log(`DegenTrail (${network.name}) deployed to ${DegenTrail.address}`);

    // Verify the contract on Etherscan for networks other than localhost
    if (network.config.chainId !== 31337) {
        await hre.run("verify:verify", {
            address: DegenTrail.address,
            constructorArguments: [blocksToAct, rollFee, rerollFee],
        });
    }
}

module.exports.tags = ["NFT", "all", "hardhat", "mumbai", "sepolia", "goerli", "fuji", "polygon", "ethereum", "avalanche", "opSepolia"];
