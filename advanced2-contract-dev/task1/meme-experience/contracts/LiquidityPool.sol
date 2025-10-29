// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LiquidityPool {
    address public _owner;
    address public _memeToken;
    uint256 public _ethReserve;
    uint256 public _tokenReserve;
    mapping(address => uint256) public _liquidityShares;
    uint256 public _totalShares;

    event AddLiquidity(address indexed provider, uint256 ethAmount, uint256 tokenAmount, uint256 shares);
    event RemoveLiquidity(address indexed provider, uint256 ethAmount, uint256 tokenAmount, uint256 shares);
    event Swap(address indexed swapper, uint256 ethIn, uint256 tokenOut, uint256 tokenIn, uint256 ethOut);

    constructor(address memeToken) {
        _owner = msg.sender;
        _memeToken = memeToken;
    }

    function addLiquidity(uint256 tokenAmount) external payable {
        require(msg.value > 0 && tokenAmount > 0, "Invalid amounts");

        uint256 shares;
        uint ethAmount = msg.value;

        if (_totalShares == 0) {
            // add liquidity firstly
            shares = msg.value;
        } else {
            uint256 ethShare = (ethAmount * _totalShares) / _ethReserve;
            uint256 tokenShare = (tokenAmount * _totalShares) / _tokenReserve;
            shares = ethShare < tokenShare ? ethShare : tokenShare;
        }

        IERC20 meme = IERC20(_memeToken);
        require(meme.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        _ethReserve += ethAmount;
        _tokenReserve += tokenAmount;
        _liquidityShares[msg.sender] += shares;
        _totalShares += shares;

        emit AddLiquidity(msg.sender, ethAmount, tokenAmount, shares);
    }

    function removeLiquidity(uint256 shares) external {
        require(shares > 0 && _liquidityShares[msg.sender] >= shares, "Invalid shares");

        uint256 ethAmount = (shares *_ethReserve) / _totalShares;
        uint256 tokenAmount = (shares *_tokenReserve) / _totalShares;

        _ethReserve -= ethAmount;
        _tokenReserve -= tokenAmount;
        _liquidityShares[msg.sender] -= shares;
        _totalShares -= shares;

        payable(msg.sender).transfer(ethAmount);
        IERC20 meme = IERC20(_memeToken);
        meme.transfer(msg.sender, tokenAmount);

        emit RemoveLiquidity(msg.sender, ethAmount, tokenAmount, shares);
    }

    // eth => token
    function swapETHForToken() external payable {
        require(msg.value > 0, "Invalid ETH amount");
        require(_ethReserve > 0 && _tokenReserve > 0, "Insufficient liquidity");

        uint256 ethIn = msg.value;
        // x*y=k  0.3% fee
        uint256 ethInWithFee = (ethIn * 997) / 1000;
        uint256 tokenOut = (_tokenReserve * ethInWithFee) / (_ethReserve + ethInWithFee);

        require(tokenOut > 0 && tokenOut < _tokenReserve, "Invalid swap");

        _ethReserve += ethIn;
        _tokenReserve -= tokenOut;

        IERC20 meme = IERC20(_memeToken);
        meme.transfer(msg.sender, tokenOut);

        emit Swap(msg.sender, ethIn, tokenOut, 0, 0);
    }

    // token => eth
    function swapTokenForETH(uint256 tokenIn) external {
        require(tokenIn > 0, "Invalid token amount");
        require(_ethReserve > 0 && _tokenReserve > 0, "No liquidity");

        // x*y=k   0.3% fee
        uint256 tokenInWithFee = (tokenIn * 997) / 1000;
        uint256 ethOut = (_ethReserve * tokenInWithFee) / (_tokenReserve + tokenInWithFee);

        require(ethOut > 0 && ethOut < _ethReserve, "Invalid swap");

        IERC20 meme = IERC20(_memeToken);
        meme.transferFrom(msg.sender, address(this), tokenIn);

        _tokenReserve += tokenIn;
        _ethReserve -= ethOut;

        payable(msg.sender).transfer(ethOut);

        emit Swap(msg.sender, 0, 0, tokenIn, ethOut);
    }

    function getSwapPrice(uint256 amountIn, bool isEthToToken) external view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");

        if (_ethReserve == 0 || _tokenReserve == 0) {
            return 0;
        }

        if (isEthToToken) {
            uint256 ethInWithFee = (amountIn * 997) / 1000;
            amountOut = (_tokenReserve * ethInWithFee) / (_ethReserve + ethInWithFee);
        } else {
            uint256 tokenInWithFee = (amountIn * 997) / 1000;
            amountOut = (_ethReserve * tokenInWithFee) / (_tokenReserve + tokenInWithFee);
        }
    }

    function getPoolInfo() external view returns (uint256, uint256, uint256) {
        return (_ethReserve, _tokenReserve, _totalShares);
    }

    function getMemeToken() external view returns (address) {
        return _memeToken;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}