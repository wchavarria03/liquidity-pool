// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TokenA.sol";
import "./TokenB.sol";

/**  
 * @title SimpleDEX
 * @dev A simple decentralized exchange (DEX) contract that allows users to swap tokens.
 */
contract SimpleDEX is ReentrancyGuard {
    TokenA public tokenA;
    TokenB public tokenB;

    uint256 public totalLPTokenSupply = 0;

    mapping(address => uint256) public addressToLPTokenBalance;

    // --- Events ---
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensBurned);
    event Swap(address indexed user, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    // --- Custom Errors ---
    error ZeroAmount();
    error InsufficientLPTokens();
    error OutputAmountZero();
    error InvalidTokenAddress();
    error IdenticalTokenAddresses();
    error ZeroTokenAddress();
    error NoLiquidity();

    constructor(address _tokenA, address _tokenB) {
        if (_tokenA == address(0) || _tokenB == address(0)) revert ZeroTokenAddress();
        if (_tokenA == _tokenB) revert IdenticalTokenAddresses();
        tokenA = TokenA(_tokenA);
        tokenB = TokenB(_tokenB);
    }

    /**
     * @notice Returns the price of the specified token in terms of the other token.
     * @param _token The address of the token to get the price for.
     * @return price The price of the specified token (with 18 decimals of precision).
     */
    function getPrice(address _token) public view returns (uint256 price) {
        uint256 reserveA = _reserveA();
        uint256 reserveB = _reserveB();
        if (reserveA == 0 || reserveB == 0) revert NoLiquidity();

        if (_token == address(tokenA)) {
            price = (reserveB * 1e18) / reserveA;
        } else if (_token == address(tokenB)) {
            price = (reserveA * 1e18) / reserveB;
        } else {
            revert InvalidTokenAddress();
        }
    }

    /**
     * @notice Adds liquidity to the pool and mints LP tokens to the provider.
     * @param amountA Amount of TokenA to add.
     * @param amountB Amount of TokenB to add.
     * @dev First provider sets the initial ratio. Subsequent providers must add in the correct ratio.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) public nonReentrant {
        if (amountA == 0 || amountB == 0) revert ZeroAmount();

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 lpTokens;
        if (totalLPTokenSupply == 0) {
            lpTokens = _sqrt(amountA * amountB);
            addressToLPTokenBalance[msg.sender] = lpTokens;
            totalLPTokenSupply = lpTokens;
        } else {
            uint256 reserveA = _reserveAExcluding(amountA);
            uint256 reserveB = _reserveBExcluding(amountB);
            lpTokens = _min(_lpTokensA(amountA, reserveA), _lpTokensB(amountB, reserveB));
            addressToLPTokenBalance[msg.sender] += lpTokens;
            totalLPTokenSupply += lpTokens;
        }

        emit LiquidityAdded(msg.sender, amountA, amountB, lpTokens);
    }

    /**
     * @notice Removes liquidity from the pool and burns LP tokens from the provider.
     * @param lpTokens Amount of LP tokens to burn.
     * @dev Returns proportional amounts of TokenA and TokenB to the provider.
     */
    function removeLiquidity(uint256 lpTokens) public nonReentrant {
        if (lpTokens == 0) revert ZeroAmount();
        if (addressToLPTokenBalance[msg.sender] < lpTokens) revert InsufficientLPTokens();

        uint256 reserveA = _reserveA();
        uint256 reserveB = _reserveB();

        uint256 amountA = _proportionalAmount(lpTokens, reserveA);
        uint256 amountB = _proportionalAmount(lpTokens, reserveB);

        addressToLPTokenBalance[msg.sender] -= lpTokens;
        totalLPTokenSupply -= lpTokens;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpTokens);
    }
    
    /**
     * @notice Swaps TokenA for TokenB using the constant product formula.
     * @param amountAIn Amount of TokenA to swap in.
     * @dev The output amount of TokenB is calculated to maintain the pool invariant.
     */
    function swapAforB(uint256 amountAIn) public nonReentrant {
        if (amountAIn == 0) revert ZeroAmount();
        uint256 reserveA = _reserveA();
        uint256 reserveB = _reserveB();
        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        uint256 amountBOut = _getAmountOut(amountAIn, reserveA, reserveB);
        if (amountBOut == 0) revert OutputAmountZero();
        tokenB.transfer(msg.sender, amountBOut);

        emit Swap(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    /**
     * @notice Swaps TokenB for TokenA using the constant product formula.
     * @param amountBIn Amount of TokenB to swap in.
     * @dev The output amount of TokenA is calculated to maintain the pool invariant.
     */
    function swapBforA(uint256 amountBIn) public nonReentrant {
        if (amountBIn == 0) revert ZeroAmount();
        uint256 reserveA = _reserveA();
        uint256 reserveB = _reserveB();
        tokenB.transferFrom(msg.sender, address(this), amountBIn);

        uint256 amountAOut = _getAmountOut(amountBIn, reserveB, reserveA);
        if (amountAOut == 0) revert OutputAmountZero();
        tokenA.transfer(msg.sender, amountAOut);

        emit Swap(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    // --- Internal helper functions ---

    /**
     * @notice Calculates the integer square root of a number.
     * @param y The input value.
     * @return z The integer square root of y.
     */
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Returns the minimum of two numbers.
     * @param a First number.
     * @param b Second number.
     * @return The smaller of a and b.
     */
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Calculates the amount of LP tokens to mint for TokenA contribution.
     * @param amountA Amount of TokenA added.
     * @param reserveA Current reserve of TokenA (excluding the new amount).
     * @return Amount of LP tokens to mint for TokenA.
     */
    function _lpTokensA(uint256 amountA, uint256 reserveA) internal view returns (uint256) {
        return (amountA * totalLPTokenSupply) / reserveA;
    }

    /**
     * @notice Calculates the amount of LP tokens to mint for TokenB contribution.
     * @param amountB Amount of TokenB added.
     * @param reserveB Current reserve of TokenB (excluding the new amount).
     * @return Amount of LP tokens to mint for TokenB.
     */
    function _lpTokensB(uint256 amountB, uint256 reserveB) internal view returns (uint256) {
        return (amountB * totalLPTokenSupply) / reserveB;
    }

    /**
     * @notice Returns the current reserve of TokenA in the pool.
     * @return The TokenA reserve.
     */
    function _reserveA() internal view returns (uint256) {
        return tokenA.balanceOf(address(this));
    }

    /**
     * @notice Returns the current reserve of TokenB in the pool.
     * @return The TokenB reserve.
     */
    function _reserveB() internal view returns (uint256) {
        return tokenB.balanceOf(address(this));
    }

    /**
     * @notice Returns the reserve of TokenA excluding a specified amount.
     * @param amountA Amount to exclude from the reserve.
     * @return The TokenA reserve minus amountA.
     */
    function _reserveAExcluding(uint256 amountA) internal view returns (uint256) {
        return tokenA.balanceOf(address(this)) - amountA;
    }

    /**
     * @notice Returns the reserve of TokenB excluding a specified amount.
     * @param amountB Amount to exclude from the reserve.
     * @return The TokenB reserve minus amountB.
     */
    function _reserveBExcluding(uint256 amountB) internal view returns (uint256) {
        return tokenB.balanceOf(address(this)) - amountB;
    }

    /**
     * @notice Calculates the proportional amount of a token for a given LP token share.
     * @param lpTokens Amount of LP tokens.
     * @param reserve The token reserve.
     * @return The proportional amount of the token.
     */
    function _proportionalAmount(uint256 lpTokens, uint256 reserve) internal view returns (uint256) {
        return (lpTokens * reserve) / totalLPTokenSupply;
    }

    /**
     * @notice Calculates the output amount for a swap using the constant product formula.
     * @param amountIn Amount of input token.
     * @param reserveIn Reserve of input token.
     * @param reserveOut Reserve of output token.
     * @return The output amount of the swap.
     */
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (reserveOut * amountIn) / (reserveIn + amountIn);
    }
}