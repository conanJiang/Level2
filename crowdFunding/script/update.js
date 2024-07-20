const {ethers, upgrades} = require("hardhat");

// 升级合约的部署代码
async function main(){
    const proxyAddr = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";
    const CrowdfundingPlatformV2 = await ethers.getContractFactory("CrowdfundingPlatformV2");
    const platform = await upgrades.upgradeProxy(proxyAddr, CrowdfundingPlatformV2);

    //   <!-- await platform.deployed();
    //   console.log("CrowdFundingPlatform deployed to:", platform.address);  updateBY leo-->
    await platform.waitForDeployment();
    console.log("CrowdFundingPlatform deployed to:", platform.target);


}

main();