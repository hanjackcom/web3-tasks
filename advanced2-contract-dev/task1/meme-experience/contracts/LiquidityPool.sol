// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidityPool is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable router;
    IUniswapV2Factory public immutable factory;
    address public immutable WETH;

    mapping(address => address) public tokenToPair;

    event LiquidityAdded(
        address indexed token,
        address indexed pair,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 liquidity
    );

    event LiquidityRemoved(
        address indexed token,
        address indexed pair,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 liquidity
    );

    event ETHForTokensSwapped(
        address indexed token,
        uint256 ethAmount,
        uint256 tokenAmount,
        address indexed recipient
    );

    event TokensForETHSwapped(
        address indexed token,
        uint256 tokenAmount,
        uint256 ethAmount,
        address indexed recipient
    );

    constructor(address router_) Ownable(msg.sender) {
        require(_router != address(0), "Invalid router address");
        router = IUniswapV2Router02(router_);
        factory = IUniswapV2Factory(router.factory());
        WETH = router.WETH();
    }

    function addLiquidityETH(
        address token,
        uint256 tokenAmount,
        uint256 minLiquidity,
        uint256 deadline
    ) external payable returns (uint256 liquidity) {
        require(token != address(0) && token != WETH, "Invalid token");
        require(tokenAmount > 0 && msg.value > 0, "Amounts must be positive");

        IERC20(token).safeApprove(address(router), tokenAmount);

        (uint256 amountETH, uint256 amountToken, uint256 liquidityOut) = router
            .addLiquidityETH{value: msg.value}(
                token,
                tokenAmount,
                0,
                0,
                msg.sender,
                deadline
            );

        require(liquidityOut >= minLiquidity, "Insufficient liquidity received");

        address pair = factory.getPair(token, WETH);
        if (tokenToPair[token] == address(0)) {
            tokenToPair[token] = pair;
        }

        emit LiquidityAdded(token, pair, amountETH, amountToken, liquidityOut);
        return liquidityOut;
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 minETH,
        uint256 minToken,
        uint256 deadline
    ) external returns (uint256 ethAmount, uint256 tokenAmount) {
        require(token != address(0) && token != WETH, "Invalid token");
        require(liquidity > 0, "Liquidity must be positive");

        address pair = tokenToPair[token];
        require(pair != address(0), "Pair not found");

        IERC20(pair).safeApprove(address(router), liquidity);

        (uint256 amountETH, uint256 amountToken) = router.removeLiquidityETH(
            token,
            liquidity,
            minETH,
            minToken,
            msg.sender,
            deadline
        );

        require(amountETH >= minETH && amountToken >= minToken, "Insufficient output");

        emit LiquidityRemoved(token, pair, amountETH, amountToken, liquidity);
        return (amountETH, amountToken);
    }

    function swapETHForTokens(
        address token,
        uint256 minTokensOut,
        uint256 deadline
    ) external payable returns (uint256 tokensOut) {
        require(token != address(0) && token != WETH, "Invalid token");
        require(msg.value > 0, "ETH amount must be positive");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;

        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            minTokensOut,
            path,
            msg.sender,
            deadline
        );

        tokensOut = amounts[1];
        require(tokensOut >= minTokensOut, "Insufficient tokens received");

        emit ETHForTokensSwapped(token, msg.value, tokensOut, msg.sender);
        return tokensOut;
    }

    function swapTokensForETH(
        address token,
        uint256 tokenAmount,
        uint256 minEthOut,
        uint256 deadline
    ) external returns (uint256 ethOut) {
        require(token != address(0) && token != WETH, "Invalid token");
        require(tokenAmount > 0, "Token amount must be positive");

        IERC20(token).safeApprove(address(router), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        uint256[] memory amounts = router.swapExactTokensForETH(
            tokenAmount,
            minEthOut,
            path,
            msg.sender,
            deadline
        );

        ethOut = amounts[1];
        require(ethOut >= minEthOut, "Insufficient ETH received");

        emit TokensForETHSwapped(token, tokenAmount, ethOut, msg.sender);
        return ethOut;
    }

    function getPairAddress(address token) external view returns (address) {
        return tokenToPair[token] != address(0)
            ? tokenToPair[token]
            : factory.getPair(token, WETH);
    }

    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    function emergencyWithdrawToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
        }
    }

    receive() external payable {}
}