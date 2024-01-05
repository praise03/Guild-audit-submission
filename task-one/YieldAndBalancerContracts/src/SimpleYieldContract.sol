//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface BalancerInterface {
    function addToPool(address _token, uint256 amount) external returns (uint256, uint256);
    function withdrawFromPool(address _token, uint256 amount, uint256 lpTokenAmount) external returns (uint256);
}

contract YieldContract is ERC20{
    error InvalidAmount();
    error TransferFailed();
    error WithdrawYieldFailed();

    address immutable balancerAddress;
    uint256 constant STAKING_RATE = 86400;

    mapping(address => mapping(address => uint256)) public userDepositsInToken;
    mapping(address token => mapping(address user => uint256 lpTokenAmount)) public userLPRewardFromToken;
    mapping(address user => uint256 timeStamp) public startTime;

    event TokenDeposited(address indexed depositor, address indexed token, uint256 rewardTokensReceived);
    event TokenWithdrawn(address indexed depositor, address indexed token, uint256 amountReceived);

    constructor (address _balancerAddress) ERC20("YieldContractReward", "YCR") {
        balancerAddress = _balancerAddress;
    }

    function depositToken(address token, uint256 depositAmount) external returns(uint256) {
        if(depositAmount == 0) revert InvalidAmount();

        uint256 yieldBalanceBefore = IERC20(token).balanceOf(address(this));
        if (!IERC20(token).transferFrom(msg.sender, address(this), depositAmount)) {
            revert TransferFailed();
        }
        uint256 yieldBalanceAfter = IERC20(token).balanceOf(address(this));

        //@dev we are using the difference due to disparities in fee on transfer tokens
        uint256 amountRecievedByYieldContract = yieldBalanceAfter - yieldBalanceBefore;

        //begin yield farming
        if(userDepositsInToken[token][msg.sender] > 0) {
            if(!withdrawYieldFarmingRewards(token)) revert WithdrawYieldFailed();
        }

        //begin generating yield token rewards
        startTime[msg.sender] = block.timestamp;
        
        
        _approveBalancer(token, depositAmount);

        //deposit user deposit into balancer pool and store balancerLp tokens recieved on behalf of user
        (uint256 amountReceivedbyPool, uint256 poolTokensReceived) = BalancerInterface(balancerAddress).addToPool(token, amountRecievedByYieldContract);
        
        //actual amount received by balancer due to fee on transfer
        userDepositsInToken[token][msg.sender] += amountReceivedbyPool;

        userLPRewardFromToken[token][msg.sender] = poolTokensReceived;
        
        emit TokenDeposited(msg.sender, token, poolTokensReceived);
        
        return poolTokensReceived;
    }

    function withdrawToken(address token, uint256 amount) external returns (uint256) {
        if(userDepositsInToken[token][msg.sender] < amount) revert InvalidAmount();

        userDepositsInToken[token][msg.sender] -= amount;

        uint256 userLpTokens = userLPRewardFromToken[token][msg.sender];

        //withdraw deposit from balancer + rewards;
        uint256 rewardsFromBalancer = BalancerInterface(balancerAddress).withdrawFromPool(token, amount, userLpTokens);

        // uint256 amountWithRewards = amount + rewardsFromBalancer;

        if(!IERC20(token).transfer(msg.sender, rewardsFromBalancer)) revert TransferFailed();

        emit TokenWithdrawn(msg.sender, token, rewardsFromBalancer);
        return rewardsFromBalancer;
    }

    //@notice function to mint yield tokens to depositors
    function mint(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    function withdrawYieldFarmingRewards(address token) public returns(bool) {
        require(userDepositsInToken[token][msg.sender] > 0, "No active stake");
        uint256 reward = getFarmingRewards(msg.sender, token);
        require(reward != 0, "No staking rewards yet");

        mint(msg.sender, reward);
        return true;
    }

    //@dev returns rewards gained from staking considering the staking duration and amount deposited
    function getFarmingRewards(address user, address token) public view returns (uint256) {
        uint256 timePassed = (block.timestamp - startTime[user]) * 10e18;
        uint256 timeRate = timePassed / STAKING_RATE;
        uint256 yield = (userDepositsInToken[token][user] * timeRate) / 10**18;
        return yield;
    }


    //@notice approve balancer to spend yield contract tokens
    function _approveBalancer(address token, uint256 amount) internal {
        IERC20(token).approve(balancerAddress, amount);
    }

}