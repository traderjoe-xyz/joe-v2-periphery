// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/libraries/math/Uint256x256Math.sol";
import "joe-v2/libraries/PriceHelper.sol";
import "joe-v2/libraries/Constants.sol";
import "joe-v2/libraries/math/SafeCast.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "joe-v2/interfaces/ILBToken.sol";

/// @title Liquidity Book periphery library for Liquidity Amount
/// @author Trader Joe
/// @notice Periphery library to help compute liquidity amounts from amounts and ids.
/// @dev The caller must ensure that the parameters are valid following the comments.
///
/// Deprecated: use LiquidityHelper instead
library LiquidityAmounts {
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    error LiquidityAmounts__LengthMismatch();

    /// @notice Return the liquidities amounts received for a given amount of tokenX and tokenY
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param ids the list of ids where the user want to add liquidity
    /// @param binStep the binStep of the pair
    /// @param amountX the amount of tokenX
    /// @param amountY the amount of tokenY
    /// @return liquidities the amounts of liquidity received
    function getLiquiditiesForAmounts(uint256[] memory ids, uint16 binStep, uint112 amountX, uint112 amountY)
        internal
        pure
        returns (uint256[] memory liquidities)
    {
        liquidities = new uint256[](ids.length);

        for (uint256 i; i < ids.length; ++i) {
            uint256 price = PriceHelper.getPriceFromId(ids[i].safe24(), binStep);

            liquidities[i] = price.mulShiftRoundDown(amountX, Constants.SCALE_OFFSET) + amountY;
        }
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
        uint256[] memory liquidities,
        uint256[] memory totalSupplies,
        uint112[] memory binReservesX,
        uint112[] memory binReservesY
    ) internal pure returns (uint256 amountX, uint256 amountY) {
        if (
            liquidities.length != totalSupplies.length && liquidities.length != binReservesX.length
                && liquidities.length != binReservesY.length
        ) revert LiquidityAmounts__LengthMismatch();

        for (uint256 i; i < liquidities.length; ++i) {
            amountX += liquidities[i].mulDivRoundDown(binReservesX[i], totalSupplies[i]);
            amountY += liquidities[i].mulDivRoundDown(binReservesY[i], totalSupplies[i]);
        }
    }

    /// @notice Return the balance of an user for a given list of ids
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user have liquidity
    /// @param LBPair The address of the LBPair
    /// @return balances the balances of the user for each id
    function getBalanceOf(address user, uint256[] memory ids, address LBPair)
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](ids.length);

        for (uint256 i; i < ids.length; ++i) {
            balances[i] = ILBToken(LBPair).balanceOf(user, ids[i].safe24());
        }
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
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory liquidities)
    {
        liquidities = new uint256[](ids.length);
        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        uint16 binStep = ILBPair(LBPair).getBinStep();

        for (uint256 i; i < ids.length; ++i) {
            uint24 id = ids[i].safe24();

            uint256 liquidity = ILBToken(LBPair).balanceOf(user, id);
            (uint256 binReserveX, uint256 binReserveY) = ILBPair(LBPair).getBin(id);
            uint256 totalSupply = ILBToken(LBPair).totalSupply(id);

            if (totalSupply > 0) {
                uint256 amountX = liquidity.mulDivRoundDown(binReserveX, totalSupply);
                uint256 amountY = liquidity.mulDivRoundDown(binReserveY, totalSupply);

                uint256 price = PriceHelper.getPriceFromId(id, binStep);

                amountsX[i] = amountX;
                amountsY[i] = amountY;

                liquidities[i] = price.mulShiftRoundDown(amountX, Constants.SCALE_OFFSET) + amountY;
            }
        }
    }

    /// @notice Return the total amounts received by an user if he were to burn all its liquidity
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user would remove its liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return totalAmountX the total amount of tokenX received by the user
    /// @return totalAmountY the total amount of tokenY received by the user
    function getTotalAmountsOf(address user, uint256[] memory ids, address LBPair)
        internal
        view
        returns (uint256 totalAmountX, uint256 totalAmountY)
    {
        for (uint256 i; i < ids.length; ++i) {
            uint24 id = ids[i].safe24();

            uint256 shares = ILBToken(LBPair).balanceOf(user, id);
            (uint256 binReserveX, uint256 binReserveY) = ILBPair(LBPair).getBin(id);
            uint256 totalShares = ILBToken(LBPair).totalSupply(id);

            totalAmountX += shares.mulDivRoundDown(binReserveX, totalShares);
            totalAmountY += shares.mulDivRoundDown(binReserveY, totalShares);
        }
    }

    /// @notice Return the list of amounts received by an user for a given list of ids
    /// @dev The caller needs to ensure that the ids are unique, if not, the result will be wrong.
    /// @param user The address of the user
    /// @param ids the list of ids where the user would remove its liquidity, ids need to be in ascending order to assert uniqueness
    /// @param LBPair The address of the LBPair
    /// @return amountsX the amounts of tokenX received by the user for each id
    /// @return amountsY the amounts of tokenY received by the user for each id
    function getAmountsOf(address user, uint256[] memory ids, address LBPair)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        for (uint256 i; i < ids.length; ++i) {
            uint24 id = ids[i].safe24();

            uint256 shares = ILBToken(LBPair).balanceOf(user, id);
            (uint256 binReserveX, uint256 binReserveY) = ILBPair(LBPair).getBin(id);
            uint256 totalShares = ILBToken(LBPair).totalSupply(id);

            amountsX[i] = shares.mulDivRoundDown(binReserveX, totalShares);
            amountsY[i] = shares.mulDivRoundDown(binReserveY, totalShares);
        }
    }
}
