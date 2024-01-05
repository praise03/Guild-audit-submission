//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BalancerHelpers.sol";

interface LPINTERFACE is IERC20{
    function mintTo(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}


contract BalancerPool is BalancerHelper {
    error ZeroAmount();
    error DepositFailed();
    error InsufficientBalance();
    error TransferFailed();

    uint256 constant SWAP_FEE = 3;
    uint256 constant POOL_FEE = 3;
    address immutable poolLiquidityToken;

    mapping(address => bool) public tokenPresent;
    mapping(address => mapping(address => uint256)) public userDepositsInToken;
    mapping(address => uint256) public feesAccured;

    address[] public poolTokens;

    constructor (address _poolLiquidityToken) {
        poolLiquidityToken = _poolLiquidityToken;
    }

    function addToPool(address _token, uint256 amount)
        external
        returns (uint256, uint256)
    {
        IERC20 token = IERC20(_token);
        if(!tokenPresent[_token]) {
            tokenPresent[_token] = true;
            poolTokens.push(_token);
        }

        uint256 tokenBalanceBefore = token.balanceOf(address(this));
        if(!token.transferFrom(msg.sender, address(this), amount)) revert DepositFailed();

        uint256 tokenInBalance = token.balanceOf(address(this));

        uint256 tokenAmountRecieved = tokenInBalance - tokenBalanceBefore;

        uint256 poolSupply = IERC20(poolLiquidityToken).totalSupply();

        uint256 tokenWeightIn = getTokenWeight(_token);
        uint256 totalWeight = getTotalPoolBalance(); 

        uint256 poolLiquidityTokensReceived = calcPoolOutGivenSingleIn(tokenInBalance, tokenWeightIn, poolSupply, totalWeight, tokenAmountRecieved, POOL_FEE);

        LPINTERFACE(poolLiquidityToken).mintTo(msg.sender, poolLiquidityTokensReceived);

        userDepositsInToken[_token][msg.sender] += tokenAmountRecieved;
        return (tokenAmountRecieved, poolLiquidityTokensReceived);
    }

    function withdrawFromPool(address _token, uint256 amount, uint256 lpTokenAmount) external returns (uint256) {
        if(amount > userDepositsInToken[_token][msg.sender]) revert InsufficientBalance();
        if(lpTokenAmount == 0) revert ZeroAmount();

        userDepositsInToken[_token][msg.sender] -= amount;

        uint256 feesAccuredFromToken = feesAccured[_token];

        uint256 usershare = (lpTokenAmount * feesAccuredFromToken) / LPINTERFACE(poolLiquidityToken).totalSupply();

        uint256 amountWithRewards = usershare + amount;

        LPINTERFACE(poolLiquidityToken).burnFrom(msg.sender, lpTokenAmount);

        if(!IERC20(_token).transfer(msg.sender, amountWithRewards)) revert TransferFailed();

        return amountWithRewards;

    } 

    function swap(address _tokenIn, address _tokenOut, uint256 amount) external returns(uint256) {
        if(amount == 0) revert ZeroAmount();
        require(tokenPresent[_tokenIn] && tokenPresent[_tokenOut], "Token Pair Doesn't exist in Pool");
        
        require(IERC20(_tokenOut).balanceOf(address(this)) > amount, "Poll Balance Insufficient");

        uint256 tokenBalanceBefore = IERC20(_tokenIn).balanceOf(address(this));
        
        if(!IERC20(_tokenIn).transferFrom(msg.sender, address(this), amount)) revert DepositFailed();


        uint256 tokenInBalanceInPool = IERC20(_tokenIn).balanceOf(address(this));

        uint256 tokenAmountRecieved = tokenInBalanceInPool - tokenBalanceBefore;

        uint256 feeIncured = (tokenAmountRecieved * SWAP_FEE) / 100;

        uint256 amountAfterFee = tokenAmountRecieved - feeIncured;

        feesAccured[_tokenIn] += feeIncured;

        (uint256 tokenInWeight, uint256 tokenOutWeight, ) = calculateTokenWeights(_tokenIn, _tokenOut);
        uint256 tokenOutBalanceInPool = IERC20(_tokenOut).balanceOf(address(this));

        uint256 tokenOutEstimate = calcOutGivenIn(tokenInBalanceInPool, tokenInWeight, tokenOutBalanceInPool, tokenOutWeight, amountAfterFee, 3);

        if(!IERC20(_tokenOut).transfer(msg.sender, tokenOutEstimate)) revert TransferFailed();

        return tokenOutEstimate; 

    }

    function calculateTokenWeights(address _tokenA, address _tokenB) public view returns(uint256 weightA, uint256 weightB, uint256 totalWeight) {
        uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));

        totalWeight = balanceA + balanceB;

        weightA = bdiv(balanceA,totalWeight);
        weightB = bdiv(balanceB,totalWeight);
    }

    function getTokenWeight(address token) public view returns (uint256) {
        if(!tokenPresent[token]) return 0;

        uint256 poolTotalBalance = getTotalPoolBalance();

        //If there are no tokens in pool i.e first deposit
        //token being deposited will have be the pool's total weight == 1
        if(poolTotalBalance == 0) return 1;

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        
        uint256 tokenWeight = bdiv(tokenBalance, poolTotalBalance);

        return tokenWeight;
    }

    function getTotalPoolBalance() public view returns (uint256 poolTotalBalance) {
        for (uint8 i; i < poolTokens.length; ++i) {
            poolTotalBalance += IERC20(poolTokens[i]).balanceOf(address(this));
        }
        return poolTotalBalance;
    }
}
