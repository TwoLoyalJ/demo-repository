// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import necessary libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract OptimizedSniperTrade is Ownable {
    address payable public creatorWallet;
    AggregatorV3Interface internal priceFeed;
    IDEXRouter public dexRouter;

    uint256 public maxLossPercent; // Maximum loss percentage
    uint256 public slippageTolerance; // Maximum allowed slippage
    uint256 public lastTradeProfit; // Stores profit from the last trade
    uint256 public lastTradeTimestamp; // Stores timestamp of the last trade

    event TradeExecuted(address indexed trader, uint256 profit, uint256 timestamp);

    constructor(address _priceFeedAddress, address _dexRouterAddress) {
        creatorWallet = payable(msg.sender); // Creator wallet for withdrawals
        priceFeed = AggregatorV3Interface(_priceFeedAddress); // Chainlink Oracle address
        dexRouter = IDEXRouter(_dexRouterAddress); // DEX Router address
        maxLossPercent = 2; // Set default loss limit to 2%
        slippageTolerance = 50; // Default slippage tolerance (0.5%)
    }

    /**
     * @notice Updates the trade configurations
     * @param _maxLossPercent Maximum loss percentage allowed
     * @param _slippageTolerance Maximum slippage percentage allowed (in basis points)
     */
    function updateConfigs(uint256 _maxLossPercent, uint256 _slippageTolerance) external onlyOwner {
        require(_maxLossPercent <= 5, "Max loss exceeds acceptable limit");
        require(_slippageTolerance <= 500, "Slippage tolerance too high");
        maxLossPercent = _maxLossPercent;
        slippageTolerance = _slippageTolerance;
    }

    /**
     * @notice Executes a trade using the DEX Router
     * @param tokenIn Address of the input token
     * @param tokenOut Address of the output token
     * @param amountIn Amount of the input token
     * @param minAmountOut Minimum amount of the output token
     * @param path Trading path for the swap
     * @param deadline Trade execution deadline
     */
    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwner {
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        // Approve DEX router to spend the input tokens
        IERC20(tokenIn).approve(address(dexRouter), amountIn);

        // Execute the trade on the DEX
        dexRo
