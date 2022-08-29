const { ethers } = require("hardhat")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    const rewardToken = await ethers.getContract("RewardToken")

    const stakingDeployment = await deploy("Staking", {
        from: deployer,
        //Notice here we are actually using the rewardToken.address as the stakingToken.address too! Its both. Both
        //... are needed to deploy our Staking contract. Look at constructor in Staking.sol 
        args: [rewardToken.address, rewardToken.address],
        log: true,
    })
}
module.exports.tags = ["all", "staking"]