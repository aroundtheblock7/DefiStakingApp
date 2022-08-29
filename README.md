# DefiStakingApp

### This project represents a Defi App similar to that used by Synthetix where rewards are paid by the second to stakeholders. Note there is a both a rewards token and the staking token and this is set in the constructor upon deployment of the Staking contract. See contracts folder for all contracts. Both of the rewardsToken and the stakingToken are also IERC20 so we have access to these functions. Run "yarn hardhat deploy" for local network deployment and "yarn hardhat deploy --network rinkeby" for rinkeby deployment.

### This was deployed using hardhat and ethers with deploy scripts (see deploy scripts files) and tests were written in test folder to ensure the correct number of tokens were paid out after the specified time. To acheive this on the local network (hardhat) we had to simulate the moving of both time and blocks. Check utils folder for these files that were used in conjuction with our test file. Run "yarn hardhat test" to see test. 

### See screen shots below for confirmation of local deployment (hardhat), deployment to rinkeby, and the passing tests from our testing file. 


<img width="1393" alt="Screen Shot 2022-08-28 at 5 18 02 PM" src="https://user-images.githubusercontent.com/81759076/187199691-2300d062-5256-4edb-8ffe-47d651c9e32b.png">
<img width="1387" alt="Screen Shot 2022-08-28 at 5 06 04 PM" src="https://user-images.githubusercontent.com/81759076/187199703-2cefd913-c5ec-421b-aa20-ea369df8b485.png">
<img width="1493" alt="Screen Shot 2022-08-29 at 8 15 59 AM" src="https://user-images.githubusercontent.com/81759076/187199718-8a3b397b-3cc6-40f4-817f-da9912cf0bea.png">
<img width="1372" alt="Screen Shot 2022-08-28 at 5 55 14 PM" src="https://user-images.githubusercontent.com/81759076/187199723-8947da73-7971-4565-9c2c-f80428d5804a.png">
<img width="1178" alt="Screen Shot 2022-08-28 at 5 57 00 PM" src="https://user-images.githubusercontent.com/81759076/187199729-578e55dc-6776-469d-a355-929d32913f33.png">
