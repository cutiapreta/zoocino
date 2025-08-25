// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleYieldFarm {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate = 100; 
    uint256 public totalStaked;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(IERC20 _stakingToken, IERC20 _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        lastUpdateTime = block.timestamp;
    }

    function updateReward(address user) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (user != address(0)) {
            rewards[user] = earned(user);
            userRewardPerTokenPaid[user] = rewardPerTokenStored;
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 timePassed = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (timePassed * rewardRate * 1e18 / totalStaked);
    }

    function earned(address user) public view returns (uint256) {
        return (userStaked[user] * (rewardPerToken() - userRewardPerTokenPaid[user])) / 1e18 + rewards[user];
    }

    function stake(uint256 amount) external {
        updateReward(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        userStaked[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        updateReward(msg.sender);
        require(userStaked[msg.sender] >= amount, "Not enough staked");
        userStaked[msg.sender] -= amount;
        totalStaked -= amount;
        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
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