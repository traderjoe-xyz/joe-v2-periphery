// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/libraries/Math512Bits.sol";
import "joe-v2/libraries/BinHelper.sol";
import "joe-v2/libraries/Constants.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "joe-v2/interfaces/ILBToken.sol";

import "../JoeV2PeripheryErrors.sol";

/// @title Liquidity Book periphery contract for Liquidity Amount
/// @author Trader Joe
/// @notice Periphery contract to help compute liquidity amounts from amounts and id
library LiquidityAmounts {
    using Math512Bits for uint256;

    /// @notice Return the liquidities amounts received for a given amount of tokenX and tokenY
    /// @param ids the list of ids where the user want to add liquidity, ids need to be in ascending order to assert uniqueness
    /// @param binStep the binStep of the pair
    /// @param amountX the amount of tokenX
    /// @param amountY the amount of tokenY
    /// @return liquidities the amounts of liquidity received
    function getLiquiditiesForAmounts(
        uint24[] calldata ids,
        uint16 binStep,
        uint112 amountX,
        uint112 amountY
    ) internal pure returns (uint256[] memory liquidities) {
        liquidities = new uint256[](ids.length);

        uint24 id;
        for (uint256 i; i < ids.length; ++i) {
            if (id >= ids[i] && id != 0) revert LiquidityAmounts__OnlyStrictlyIncreasingId();
            id = ids[i];

            uint256 price = BinHelper.getPriceFromId(id, binStep);

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
        uint256[] calldata liquidities,
        uint256[] calldata totalSupplies,
        uint112[] calldata binReservesX,
        uint112[] calldata binReservesY
    ) internal pure returns (uint256 amountX, uint256 amountY) {
        if (
            liquidities.length != totalSupplies.length &&
            liquidities.length != binReservesX.length &&
            liquidities.length != binReservesY.length
        ) revert LiquidityAmounts__LengthMismatch();

        for (uint256 i; i < liquidities.length; ++i) {
            amountX += liquidities[i].mulDivRoundDown(binReservesX[i], totalSupplies[i]);
            amountY += liquidities[i].mulDivRoundDown(binReservesY[i], totalSupplies[i]);
        }
    }

    /// @notice Return the ids and liquidities of an user
    /// @param user The address of the user
    /// @param LBPair The address of the LBPair
    /// @return ids the list of ids where the user has liquidity
    /// @return liquidities the list of amount of liquidity of the user
    function getLiquiditiesOf(address user, address LBPair)
        internal
        view
        returns (uint24[] memory ids, uint256[] memory liquidities)
    {
        uint256 positionNumber = ILBToken(LBPair).userPositionNumber(user);

        liquidities = new uint256[](positionNumber);
        ids = new uint24[](positionNumber);

        for (uint256 i; i < positionNumber; ++i) {
            uint24 id = uint24(ILBToken(LBPair).userPositionAtIndex(user, i));

            ids[i] = id;
            liquidities[i] = ILBToken(LBPair).balanceOf(user, id);
        }
    }

    /// @notice Return the amounts received by an user if he were to burn all its liquidity
    /// @param user The address of the user
    /// @param LBPair The address of the LBPair
    /// @return amountX the amount of tokenX received by the user
    /// @return amountY the amount of tokenY received by the user
    function getAmountsOf(address user, address LBPair) internal view returns (uint256 amountX, uint256 amountY) {
        uint256 positionNumber = ILBToken(LBPair).userPositionNumber(user);

        for (uint256 i; i < positionNumber; ++i) {
            uint24 id = uint24(ILBToken(LBPair).userPositionAtIndex(user, i));
            uint256 liquidity = ILBToken(LBPair).balanceOf(user, id);

            (uint256 binReserveX, uint256 binReserveY) = ILBPair(LBPair).getBin(id);
            uint256 totalSupply = ILBToken(LBPair).totalSupply(id);

            amountX += liquidity.mulDivRoundDown(binReserveX, totalSupply);
            amountY += liquidity.mulDivRoundDown(binReserveY, totalSupply);
        }
    }
}
