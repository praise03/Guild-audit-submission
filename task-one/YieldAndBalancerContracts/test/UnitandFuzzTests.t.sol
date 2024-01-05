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

    function testDepositIntoYieldContract() public {
        uint256 amount = 10e18;
        // vm.assume(amount != 0);
        address alice = makeAddr("alice");
        vm.prank(deployer);
        feeOnTransferToken1.transfer(alice, amount);

        vm.startPrank(alice);
        feeOnTransferToken1.approve(address(yieldContract), amount);
        yieldContract.depositToken(address(feeOnTransferToken1), amount);
        
    }

}
