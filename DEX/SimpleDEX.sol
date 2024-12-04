// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/// @title Simple Decentralized Exchange (DEX)
/// @notice This contract facilitates token swaps and liquidity management
/// @dev Uses constant product formula for swaps
/// @author [Mario A. Parodi]
contract SimpleDEX is Ownable {
    /// @notice Token A in the liquidity pool
    IERC20 public tokenA;

    /// @notice Token B in the liquidity pool
    IERC20 public tokenB;

    /// @notice Emitted when liquidity is added
    /// @param amountA The amount of token A added
    /// @param amountB The amount of token B added
    event LiquidityAdded(uint256 amountA, uint256 amountB);
    
    /// @notice Emitted when liquidity is removed
    /// @param amountA The amount of token A removed
    /// @param amountB The amount of token B removed
    event LiquidityRemoved(uint256 amountA, uint256 amountB);

    /// @notice Emitted when a token swap occurs
    /// @param user The address of the user performing the swap
    /// @param amountIn The input token amount
    /// @param amountOut The output token amount
    event TokenSwapped(address indexed user, uint256 amountIn, uint256 amountOut);

    /// @notice Adds liquidity to the pool
    /// @dev Only callable by the owner
    /// @param amountA The amount of token A to add
    /// @param amountB The amount of token B to add
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(amountA, amountB);
    }

/// @notice Removes liquidity from the pool
    /// @dev Only callable by the owner
    /// @param amountA The amount of token A to remove
    /// @param amountB The amount of token B to remove
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= tokenA.balanceOf(address(this)) && amountB <= tokenB.balanceOf(address(this)), "Low liquidity");

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB);
    }

    /// @notice Swaps token A for token B
    /// @param amountAIn The amount of token A to swap

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be > 0");

        uint256 amountBOut = getAmountOut(amountAIn, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        emit TokenSwapped(msg.sender, amountAIn, amountBOut);
    }

    /// @notice Swaps token B for token A
    /// @param amountBIn The amount of token B to swap
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be > 0");

        uint256 amountAOut = getAmountOut(amountBIn, tokenB.balanceOf(address(this)), tokenA.balanceOf(address(this)));

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        emit TokenSwapped(msg.sender, amountBIn, amountAOut);
    }
 /// @notice Gets the price of a token relative to the other
    /// @param _token Address of the token to price
    /// @return The price in terms of the other token
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");

        return _token == address(tokenA)
            ? (tokenB.balanceOf(address(this)) * 1e18) / tokenA.balanceOf(address(this))
            : (tokenA.balanceOf(address(this)) * 1e18) / tokenB.balanceOf(address(this));
    }

    /// @notice Calculates the output amount of a swap
    /// @dev Implements constant product formula
    /// @param amountIn The input token amount
    /// @param reserveIn The reserve of the input token
    /// @param reserveOut The reserve of the output token
    /// @return The amount of output tokens
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}



























    










    
