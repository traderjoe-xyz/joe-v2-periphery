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
    function getLiquiditiesForAmounts(
        uint256[] calldata ids,
        uint16 binStep,
        uint112 amountX,
        uint112 amountY
    ) external pure returns (uint256[] memory liquidities) {
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

    /// @notice Return the ids and liquidities of an user
    /// @param user The address of the user
    /// @param ids the list of ids where the user have liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return liquidities the list of amount of liquidity of the user
    function getLiquiditiesOf(
        address user,
        uint256[] calldata ids,
        address LBPair
    ) external view returns (uint256[] memory liquidities) {
        return LiquidityAmounts.getLiquiditiesOf(user, ids, LBPair);
    }

    /// @notice Return the amounts received by an user if he were to burn all its liquidity
    /// @param user The address of the user
    /// @param ids the list of ids where the user would remove its liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return amountX the amount of tokenX received by the user
    /// @return amountY the amount of tokenY received by the user
    function getAmountsOf(
        address user,
        uint256[] calldata ids,
        address LBPair
    ) external view returns (uint256 amountX, uint256 amountY) {
        return LiquidityAmounts.getAmountsOf(user, ids, LBPair);
    }
}
