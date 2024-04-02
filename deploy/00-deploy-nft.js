const { ethers, network } = require("hardhat");
const fs = require("fs").promises;

module.exports = async ({ deployments, getNamedAccounts }) => {
    const existingConfig = JSON.parse(await fs.readFile("config/deployment-config.json", "utf8"));

    const { name, symbol, owner, base_uri } = existingConfig[network.name].NFT;

    const { deploy, log } = deployments;

    const { deployer } = await getNamedAccounts();

    const args = [name, symbol, owner];
    const waitConfirmation = network.config.chainId === 31337 ? 0 : 6;

    const NFT = await deploy("NFT", {
        from: deployer,
        args,
        automine: true,
        log: true,
        waitConfirmations: network.config.chainId === 31337 ? 0 : 6
    });

    log(`NFT (${network.name}) deployed to ${NFT.address}`);

    const signers = await ethers.getSigners();

    const NFTContract = await ethers.getContractAt("NFT", NFT.address, signers[0]);

    const setBaseUriTx = await NFTContract.setBaseURI(base_uri);
    await setBaseUriTx.wait(waitConfirmation);

    log(`NFT (${network.name}) base uri is configured to: ${base_uri}`)

    // mint 3 NFTs to the owner
    for (let i = 0; i < 3; i++) {
        const mintTx1 = await NFTContract.safeMint(owner);
    }

    // Verify the contract on Etherscan for networks other than localhost
    if (network.config.chainId !== 31337) {
        await hre.run("verify:verify", {
            address: NFT.address,
            constructorArguments: args,
        });
    }
}

module.exports.tags = ["NFT", "all", "hardhat", "mumbai", "sepolia", "goerli", "fuji", "polygon", "ethereum", "avalanche", "opSepolia"];
