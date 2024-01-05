//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zero is ERC20 {
    uint256 constant FEE_ON_TRANSFER = 3;
    constructor() ERC20("Zero", "ZRO") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * FEE_ON_TRANSFER) / 100;
        uint256 amountMinusFee = amount - fee;
        _transfer(msg.sender, to, amountMinusFee);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * FEE_ON_TRANSFER) / 100;
        uint256 amountMinusFee = amount - fee;
        _spendAllowance(from, msg.sender, amountMinusFee);
        _transfer(from, to, amountMinusFee);
        return true;
    }
}

contract One is ERC20 {
    uint256 constant FEE_ON_TRANSFER = 3;
    constructor() ERC20("One", "ONE") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * FEE_ON_TRANSFER) / 100;
        uint256 amountMinusFee = amount - fee;
        _transfer(msg.sender, to, amountMinusFee);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * FEE_ON_TRANSFER) / 100;
        uint256 amountMinusFee = amount - fee;
        _spendAllowance(from, msg.sender, amountMinusFee);
        _transfer(from, to, amountMinusFee);
        return true;
    }
}

contract BalancerToken is ERC20, Ownable{

    error NotMinter();
    error TransferNotSupported();
    
    constructor() ERC20("BalancerLiquidityToken", "BLT"){
        
    }

    function mintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function transfer(address, uint256) public virtual override returns (bool) {
        revert TransferNotSupported();
    }

    function _transfer(address from, address to, uint256 value) internal override {
        revert TransferNotSupported();
    }

    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        revert TransferNotSupported();
    }

}