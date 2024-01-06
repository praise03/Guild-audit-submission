// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/SimpleBalancerPool.sol";
import "../src/SimpleYieldContract.sol";
import "../src/Tokens.sol";

contract SimpleBalancerAndYieldTest is Test {
    BalancerPool balancer;
    YieldContract yieldContract;
    BalancerToken balancerLiquidityToken;
    Zero feeOnTransferToken1;
    One feeOnTransferToken2;
    address deployer;

    function setUp() public {
        deployer = makeAddr("deployer");

        vm.startPrank(deployer);
        feeOnTransferToken1 = new Zero();
        feeOnTransferToken2 = new One();
        balancerLiquidityToken = new BalancerToken();

        balancer = new BalancerPool(address(balancerLiquidityToken));
        yieldContract = new YieldContract(address(balancer));

        balancerLiquidityToken.mintTo(address(deployer), 10e18);
        balancerLiquidityToken.transferOwnership(address(balancer));
        vm.stopPrank();
    }

    // modifier depositedIntoYield() {
        
    // }

    function testAll() public {
        uint256 amount = 10e18;
        // vm.assume(amount != 0);
        uint256 startTime = block.timestamp;
        address alice = makeAddr("alice");
        
        vm.startPrank(deployer);
        feeOnTransferToken1.transfer(alice, amount);
        feeOnTransferToken2.transfer(alice, amount);
        vm.stopPrank();

        //alice deposits both tokens into yield contract which adds them to the balancer pool
        vm.startPrank(alice);
        feeOnTransferToken1.approve(address(yieldContract), amount);
        yieldContract.depositToken(address(feeOnTransferToken1), amount);
        feeOnTransferToken2.approve(address(yieldContract), amount);
        yieldContract.depositToken(address(feeOnTransferToken2), amount);

        //increase timestamp to allow yield grow
        vm.warp(100);   
        vm.stopPrank();

        //mint some tokens to new address to test swapping
        vm.prank(deployer);
        feeOnTransferToken1.mint(address(2), 10e18);

        //swap some 5 of token1 for token 2 //returns 3.3
        vm.startPrank(address(2));
        feeOnTransferToken1.approve(address(balancer), 10e18);
        uint256 token2received = balancer.swap(address(feeOnTransferToken1), address(feeOnTransferToken2), 5e18);
        console2.log("For swappping 5 token2's to token1 user gets:");
        console2.log(token2received);
        vm.stopPrank();

        // uint256 depositedAmount = (amount - ( (amount * 3) /100 ));
        // uint256 yieldRewardAtCurrentTimeStamp = yieldContract.getFarmingRewards(alice, address(feeOnTransferToken1));
        console2.log("-------------");
        //alice withdraws her token deposit and yield farming rewards
        vm.startPrank(alice);
        console2.log("For withdrawing 9 out of her deposited token1, alice gets: ");
        console2.log(yieldContract.withdrawToken(address(feeOnTransferToken1), 9e18));
        yieldContract.withdrawYieldFarmingRewards(address(feeOnTransferToken1));
        vm.stopPrank();
        
        console2.log("------------------");

        console2.log("alice yield rewards after timestamp+100: ");
        console2.log(yieldContract.balanceOf(alice));
    }

}
