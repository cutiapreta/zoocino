// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleAMM {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    event Swap(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event AddLiquidity(address indexed user, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed user, uint256 amountA, uint256 amountB);

    constructor(IERC20 _tokenA, IERC20 _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA += amountA;
        reserveB += amountB;
        uint256 liquidityMinted = (amountA * amountB) / 1e18; // Simplified liquidity calculation
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;
        emit AddLiquidity(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 liquidityAmount) external {
        require(liquidity[msg.sender] >= liquidityAmount, "Not enough liquidity");
        uint256 amountA = (reserveA * liquidityAmount) / totalLiquidity;
        uint256 amountB = (reserveB * liquidityAmount) / totalLiquidity;
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;
        reserveA -= amountA;
        reserveB -= amountB;
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        emit RemoveLiquidity(msg.sender, amountA, amountB);
    }

    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        if (tokenIn == address(tokenA)) {
            amountOut = (reserveB * amountIn) / reserveA;
            reserveA += amountIn;
            reserveB -= amountOut;
            tokenB.transfer(msg.sender, amountOut);
        } else {
            amountOut = (reserveA * amountIn) / reserveB;
            reserveB += amountIn;
            reserveA -= amountOut;
            tokenA.transfer(msg.sender, amountOut);
        }
        emit Swap(msg.sender, tokenIn, amountIn, tokenIn == address(tokenA) ? address(tokenB) : address(tokenA), amountOut);
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