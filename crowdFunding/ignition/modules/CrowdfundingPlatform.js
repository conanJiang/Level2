const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CrowdfundingPlatformModule", (m) => {

  const crowdfundingPlatform = m.contract("CrowdfundingPlatform");
  console.log("CrowdfundingPlatform deployed to:", crowdfundingPlatform.target);

  return { crowdfundingPlatform };
});


