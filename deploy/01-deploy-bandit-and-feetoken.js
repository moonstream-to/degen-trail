const { ethers, network } = require("hardhat");
const fs = require("fs").promises;

module.exports = async ({ deployments, getNamedAccounts }) => {
    const existingConfig = JSON.parse(await fs.readFile("config/deployment-config.json", "utf8"));

    const { name, symbol, owner, initialSupply } = existingConfig[network.name].FeeToken;

    const { deploy, log } = deployments;

    const { deployer } = await getNamedAccounts();

    const args = [name, symbol, initialSupply, owner];

    const waitConfirmation = network.config.chainId === 31337 ? 0 : 6;

    const FeeToken = await deploy("FeeToken", {
        from: deployer,
        args,
        automine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 0 : 6
    });

    log(`Fee Token (${network.name}) deployed to ${FeeToken.address}`);

    const { blocksToAct, rollFee, rerollFee } = existingConfig[network.name].Bandit;
    const FeeTokenAddress = FeeToken.address;

    const Bandit = await deploy("Bandit", {
        from: deployer,
        args: [blocksToAct, FeeTokenAddress, rollFee, rerollFee],
        automine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 0 : 6
    });

    log(`Bandit (${network.name}) deployed to ${Bandit.address}`);

    // Verify the contract on Etherscan for networks other than localhost
    if (network.config.chainId !== 31337) {
        await hre.run("verify:verify", {
            address: NFT.address,
            constructorArguments: args,
        });
    }
}

module.exports.tags = ["NFT", "all", "hardhat", "mumbai", "sepolia", "goerli", "fuji", "polygon", "ethereum", "avalanche", "opSepolia"];
