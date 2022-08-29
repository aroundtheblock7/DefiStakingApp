// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//stake: Lock tokens into our smart contract
//withdraw/unstake- unlock tokens and pull out of contract
//claimReward- user gets their reward tokens
//whats a good reward mechanism (reward math) ?
//this contract will only allow for staking a single ERC token
//remeber our contract can not call "approve function", this needs to be on front end for user to call
//external functions are a little cheaper than public so we will use them here as the functions will be called from outside contract
//APR in a staking pool like this changes based on how many people are in the pool and how long they are in so can't really give APR

contract Staking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    error Staking_TransferFailed();
    error Withdrawal_TransferFailed();
    error Staking_NeedsMoreThanZero();

    //someone's addres => how much they staked
    mapping(address => uint256) public s_balances;

    //mapping of how much each address has been paid
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    //a mapping of how much rewards each address has
    mapping(address => uint256) public s_rewards;

    modifier updateReward(address account) {
        //how much reward per token?
        //Then we need to get last timestamp.
        //so we can say btween time peridos of 12pm -1pm, user earned X tokens.
        //the amount given out is always going to be diff depending on the time period stocked
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    //This will make sure users are withdrawing and staking more than 0.
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking_NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        //first we want to get their current balance
        uint256 currentBalance = s_balances[account];
        // next how much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        // now we'll need the currentRewardPerToken which is calculated via our rewardPerToken function
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 _earned = ((currentBalance *
            (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return _earned;
    }

    //We need to have our updateReward modifier in here so when ever anyone stakes it updates the reward of msg.sender
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        //keep track of how much this user has staked
        //keep track of how much we have total
        //transfer the token to this contract
        s_balances[msg.sender] = s_balances[msg.sender].add(amount);
        s_totalSupply = s_totalSupply.add(amount);
        //we could create a check that  user has "approved" as transferFrom will not execute without function approve
        //user calls IERC20 approve from function on front end, it should not be included in our contract
        bool success = IERC20(s_stakingToken).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        //this is a less gas expensive way than doing require(success, "Failed") because Failed is a string which is expensive
        if (!success) {
            revert Staking_TransferFailed();
        }
    }

    //When we withdraw we need to update the rewards of msg.sender so we need modifier here too
    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        s_balances[msg.sender] = s_balances[msg.sender].sub(amount);
        s_totalSupply = s_totalSupply.sub(amount);
        //we call transfer because we have the tokens already. We are going to transfer from us to user.
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Withdrawal_TransferFailed();
        }
    }

    //When we claimReward we need to update the rewards of msg.sender so we need modifier here too
    function claimReward() external updateReward(msg.sender) {
        //How much reward do they get? Each implementation is slighly diff but
        //We will use an implementation fundamental/common to the defi world which is tokens per second.
        //This contract is going to emit X tokens per second and disperse them to all stakers
        //100 tokens per second
        //50 staked tokens, 20 staked tokens, 30 staked tokens
        //50 reward tokens, 20 reward tokens, 30 reward tokens
        //staked: 100, 50, 20, 30 (200 tokens); Now we divide everyones stake by 2 because we are in the 2nd sec.
        //rewards: 50, 25, 10, 15
        //why not 1 to 1 staked : reward? It will bankrupt the protocol
        // see Word Doc in project folder for better explanation of math and reward calculations
        // What we are ultimatley using to do our calc to update rewards is our modifier updateReward
        // For example lets say for 5 secs, 1 person had a 100 tokens staked = reward 500 tokens
        //@6 seconds, 2 people have 100 tokens staked each:
        //     Person 1: 550 tokens
        //     Person 2: 50 tokens
        // ok btwn seconds 1 and 5, person 1 got 500 tokens
        // ok at second 6 on, person 1 gets 50 tokens now
        // we need to continually update for each seperate user based on time frames they are staking
        // Sincw we have all the calcs done and have updateReward modifier we can just reward = s_rewards[msg.sender]
        uint256 reward = s_rewards[msg.sender];
        // now we can just transfer msg.sender his reward
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking_TransferFailed();
        }
    }

    //rewardPerToken based on how long its been during the most recent snapshot
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        //s_rewardPerTokenStored is what they previously earned, so we add that to the new earnings
        //Remember we aer doing 1e18 because we want it in wei
        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }
}
