async function main() {
    // Deploy dETH first
    const DepositETH = await ethers.getContractFactory("DepositETH");
    const dETH = await DepositETH.deploy();
    await dETH.waitForDeployment();

    console.log("dETH deployed to:", dETH.target);

    // Deploy sETH with dETH address as parameter
    const StakedETH = await ethers.getContractFactory("StakedETH");
    const sETH = await StakedETH.deploy(dETH.target);
    await sETH.waitForDeployment();

    console.log("sETH deployed to:", sETH.target);

    // Deploy Governance with sETH address as parameter
    const Governance = await ethers.getContractFactory("Governance");
    const governance = await Governance.deploy(sETH.target);
    await governance.waitForDeployment();

    console.log("Governance deployed to:", governance.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});