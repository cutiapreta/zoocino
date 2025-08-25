// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleLending {
    IERC20 public token;
    IERC20 public collateralToken;
    mapping(address => uint256) public borrowBalance;
    mapping(address => uint256) public collateralBalance;
    uint256 public totalBorrows;
    uint256 public interestRate = 1000; // 10% annual interest, scaled by 1e4
    uint256 public lastUpdateTime;
    uint256 public totalReserves;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 collateralSeized);

    constructor(IERC20 _token, IERC20 _collateralToken) {
        token = _token;
        collateralToken = _collateralToken;
        lastUpdateTime = block.timestamp;
    }

    function depositCollateral(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(collateralBalance[msg.sender] > 0, "No collateral");
        updateInterest();
        uint256 maxBorrow = (collateralBalance[msg.sender] * 70) / 100; // 70% LTV
        require(borrowBalance[msg.sender] + amount <= maxBorrow, "Exceeds borrow limit");
        token.transfer(msg.sender, amount);
        borrowBalance[msg.sender] += amount;
        totalBorrows += amount;
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        updateInterest();
        token.transferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
        totalBorrows -= amount;
        emit Repaid(msg.sender, amount);
    }

    function updateInterest() public {
        uint256 timePassed = block.timestamp - lastUpdateTime;
        if (timePassed > 0) {
            uint256 interest = (totalBorrows * interestRate * timePassed) / (365 days * 1e4);
            totalBorrows += interest;
            totalReserves += interest;
            lastUpdateTime = block.timestamp;
        }
    }

    function liquidate(address user) external {
        updateInterest();
        uint256 maxBorrow = (collateralBalance[user] * 70) / 100;
        require(borrowBalance[user] > maxBorrow, "Not liquidatable");
        uint256 collateralSeized = collateralBalance[user];
        collateralBalance[user] = 0;
        borrowBalance[user] = 0;
        collateralToken.transfer(msg.sender, collateralSeized);
        emit Liquidated(user, collateralSeized);
    }
}




interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}