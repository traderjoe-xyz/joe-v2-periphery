// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./periphery/LiquidityAmounts.sol";

/// @title Liquidity Book periphery contract for Liquidity Amount
/// @author Trader Joe
/// @notice Periphery contract to help compute liquidity amounts from amounts and ids
contract LiquidityAmountsContract {
    /// @notice Return the liquidities amounts received for a given amount of tokenX and tokenY
    /// @param ids the list of ids where the user want to add liquidity, ids need to be in ascending order to assert uniqueness
    /// @param binStep the binStep of the pair
    /// @param amountX the amount of tokenX
    /// @param amountY the amount of tokenY
    /// @return liquidities the amounts of liquidity received
    function getLiquiditiesForAmounts(uint256[] calldata ids, uint16 binStep, uint112 amountX, uint112 amountY)
        external
        pure
        returns (uint256[] memory liquidities)
    {
        return LiquidityAmounts.getLiquiditiesForAmounts(ids, binStep, amountX, amountY);
    }

    /// @notice Return the amounts of token received for a given amount of liquidities
    /// @dev The different arrays needs to use the same binId for each index
    /// @param liquidities the list of liquidity amounts for each binId
    /// @param totalSupplies the list of totalSupply for each binId
    /// @param binReservesX the list of reserve of token X for each binId
    /// @param binReservesY the list of reserve of token Y for each binId
    /// @return amountX the amount of tokenX received by the user
    /// @return amountY the amount of tokenY received by the user
    function getAmountsForLiquidities(
        uint256[] calldata liquidities,
        uint256[] calldata totalSupplies,
        uint112[] calldata binReservesX,
        uint112[] calldata binReservesY
    ) external pure returns (uint256 amountX, uint256 amountY) {
        return LiquidityAmounts.getAmountsForLiquidities(liquidities, totalSupplies, binReservesX, binReservesY);
    }

    /// @notice Return the balance of an user for a given list of ids
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user have liquidity
    /// @param LBPair The address of the LBPair
    /// @return balances the balances of the user for each id
    function getBalanceOf(address user, uint256[] calldata ids, address LBPair)
        external
        view
        returns (uint256[] memory balances)
    {
        return LiquidityAmounts.getBalanceOf(user, ids, LBPair);
    }

    /// @notice Return the liquidity amounts and the amounts of token in each bin for a given list of ids
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user have liquidity
    /// @param LBPair The address of the LBPair
    /// @return amountsX the amounts of token X of the user for each id
    /// @return amountsY the amounts of token Y of the user for each id
    /// @return liquidities the liquidity amounts of the user for each id
    function getAmountsAndLiquiditiesOf(address user, uint256[] memory ids, address LBPair)
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory liquidities)
    {
        return LiquidityAmounts.getAmountsAndLiquiditiesOf(user, ids, LBPair);
    }

    /// @notice Return the total amounts received by an user if he were to burn all its liquidity
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user would remove its liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return totalAmountX the total amount of tokenX received by the user
    /// @return totalAmountY the total amount of tokenY received by the user
    function getTotalAmountsOf(address user, uint256[] memory ids, address LBPair)
        external
        view
        returns (uint256 totalAmountX, uint256 totalAmountY)
    {
        return LiquidityAmounts.getTotalAmountsOf(user, ids, LBPair);
    }

    /// @notice Return the list of amounts received by an user for a given list of ids
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user would remove its liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return amountsX the amounts of tokenX received by the user for each id
    /// @return amountsY the amounts of tokenY received by the user for each id
    function getAmountsOf(address user, uint256[] memory ids, address LBPair)
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityAmounts.getAmountsOf(user, ids, LBPair);
    }
}
