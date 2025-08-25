// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleStaking {
    IERC20 public token;
    uint256 public rewardRate;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastUpdateTime;

    constructor(IERC20 _token, uint256 _rewardRate) {
        token = _token;
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function getReward() external {
        uint256 reward = calculateReward(msg.sender);
        token.transfer(msg.sender, reward);
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 timePassed = block.timestamp - lastUpdateTime[user];
        return balances[user] * timePassed * rewardRate;
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