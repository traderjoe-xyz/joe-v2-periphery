// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {PriceHelper} from "joe-v2/libraries/PriceHelper.sol";
import {BinHelper} from "joe-v2/libraries/BinHelper.sol";
import {SafeCast} from "joe-v2/libraries/math/SafeCast.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

/**
 * @title Liquidity Book periphery library for Liquidity and Fees Amounts
 * @notice Periphery library to help compute liquidity and fees amounts from amounts and ids.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
library LiquidityHelper {
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    error FeesAmounts__LengthMismatch();

    /**
     * @dev Return the shares of the receipt token for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return balances The balance of the receipt token for each id
     */
    function getSharesOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            balances[i] = lbPair.balanceOf(user, ids[i].safe24());

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidity (calculated using the constant sum formula: p*x + y) for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory liquidities)
    {
        liquidities = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsOfAtId(lbPair, user, id);

            liquidities[i] = getLiquidityFromId(amountX, amountY, id, binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return amountsX The list of amounts of token X
     * @return amountsY The list of amounts of token Y
     */
    function getAmountsOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            (amountsX[i], amountsY[i]) = getAmountsOfAtId(lbPair, user, ids[i].safe24());

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the shares minted for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return shares The amount of shares of the receipt token
     */
    function getSharesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) internal view returns (uint256[] memory shares) {
        if (ids.length != amountsX.length || ids.length != amountsY.length) revert FeesAmounts__LengthMismatch();

        shares = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            uint256 price = PriceHelper.getPriceFromId(id, binStep);

            uint256 liquidity = getLiquidityFromPrice(amountsX[i], amountsY[i], price);

            shares[i] = getShareForLiquidity(lbPair, id, liquidity, price);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidities for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) internal view returns (uint256[] memory liquidities) {
        if (ids.length != amountsX.length || ids.length != amountsY.length) revert FeesAmounts__LengthMismatch();

        liquidities = new uint256[](ids.length);

        uint16 binStep = lbPair.getBinStep();

        for (uint256 i; i < ids.length;) {
            liquidities[i] = getLiquidityFromId(amountsX[i], amountsY[i], ids[i].safe24(), binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidities for a given list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        internal
        view
        returns (uint256[] memory liquidities)
    {
        if (ids.length != shares.length) revert FeesAmounts__LengthMismatch();

        liquidities = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsForShare(lbPair, id, shares[i]);

            liquidities[i] = getLiquidityFromId(amountX, amountY, id, binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        if (ids.length != shares.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            (uint256 amountX, uint256 amountY) = getAmountsForShare(lbPair, ids[i], shares[i]);

            amountsX[i] = amountX;
            amountsY[i] = amountY;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        if (ids.length != liquidities.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint256 price = PriceHelper.getPriceFromId(ids[i].safe24(), binStep);

            (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(ids[i].safe24());
            uint256 binLiquidity = getLiquidityFromPrice(binReserveX, binReserveY, price);

            uint256 liquidity = liquidities[i];

            (amountsX[i], amountsY[i]) = binLiquidity == 0
                ? (0, 0)
                : (
                    liquidity.mulDivRoundDown(binReserveX, binLiquidity),
                    liquidity.mulDivRoundDown(binReserveY, binLiquidity)
                );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the shares for a given list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return shares The share for each id
     */
    function getSharesForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        internal
        view
        returns (uint256[] memory shares)
    {
        if (ids.length != liquidities.length) revert FeesAmounts__LengthMismatch();

        shares = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint256 price = PriceHelper.getPriceFromId(ids[i].safe24(), binStep);

            shares[i] = getShareForLiquidity(lbPair, ids[i], liquidities[i], price);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousX The list of previous amounts of token X
     * @param previousY The list of previous amounts of token Y
     * @return amountsX The amount of token X for each id (including fees)
     * @return amountsY The amount of token Y for each id (including fees)
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getAmountsAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousX,
        uint256[] memory previousY
    )
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory feesX, uint256[] memory feesY)
    {
        if (ids.length != previousX.length || ids.length != previousY.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);
        feesX = new uint256[](ids.length);
        feesY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsOfAtId(lbPair, user, id);

            amountsX[i] = amountX;
            amountsY[i] = amountY;

            (uint256 feeX, uint256 feeY) = getFeesAtId(binStep, id, previousX[i], previousY[i], amountX, amountY);

            feesX[i] = feeX;
            feesY[i] = feeY;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the fee shares and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousLiquidities The list of previous liquidities
     * @return feeShares The fee shares for each id. This is the amount to burn to receive the fees,
     * in 128.128 fixed point number
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getFeeSharesAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousLiquidities
    ) internal view returns (uint256[] memory feeShares, uint256[] memory feesX, uint256[] memory feesY) {
        if (ids.length != previousLiquidities.length) revert FeesAmounts__LengthMismatch();

        feeShares = new uint256[](ids.length);
        feesX = new uint256[](ids.length);
        feesY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            uint256 share = getShareOfAtId(lbPair, user, id);
            (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id);
            uint256 totalShares = lbPair.totalSupply(id);

            (uint256 amountX, uint256 amountY) = totalShares == 0
                ? (0, 0)
                : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));

            uint256 previousLiquidity = previousLiquidities[i];

            uint256 currentLiquidity = getLiquidityFromPrice(amountX, amountY, PriceHelper.getPriceFromId(id, binStep));

            uint256 feeShare = currentLiquidity > previousLiquidity
                ? (currentLiquidity - previousLiquidity).mulDivRoundDown(share, currentLiquidity)
                : 0;

            feeShares[i] = feeShare;

            (feesX[i], feesY[i]) = totalShares == 0
                ? (0, 0)
                : (feeShare.mulDivRoundDown(binReserveX, totalShares), feeShare.mulDivRoundDown(binReserveY, totalShares));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a given share amount
     * @param lbPair The pair
     * @param id The id
     * @param share The share amount
     * @return amountX The amount of token X
     * @return amountY The amount of token Y
     */
    function getAmountsForShare(ILBPair lbPair, uint256 id, uint256 share)
        internal
        view
        returns (uint256 amountX, uint256 amountY)
    {
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id.safe24());
        uint256 totalShares = lbPair.totalSupply(id);

        (amountX, amountY) = totalShares == 0
            ? (0, 0)
            : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));
    }

    /**
     * @dev Return the share amount of a given user at a given id
     * @param lbPair The pair
     * @param user The user
     * @param id The id
     * @return the share amount of the user at the given id
     */
    function getShareOfAtId(ILBPair lbPair, address user, uint24 id) internal view returns (uint256) {
        return lbPair.balanceOf(user, id);
    }

    /**
     * @dev Return the amounts of x and y of a given user at a given id
     * @param lbPair The pair
     * @param user The user
     * @param id The id
     * @return amountX The amount of token X
     * @return amountY The amount of token Y
     */
    function getAmountsOfAtId(ILBPair lbPair, address user, uint24 id)
        internal
        view
        returns (uint256 amountX, uint256 amountY)
    {
        uint256 share = getShareOfAtId(lbPair, user, id);
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id);
        uint256 totalShares = lbPair.totalSupply(id);

        (amountX, amountY) = totalShares == 0
            ? (0, 0)
            : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));
    }

    /**
     * @dev Return the fees earned of a given user at a given id from a given amounts of x and y
     * @param binStep The binStep of the pair
     * @param id The id
     * @param previousX The previous amount of token X
     * @param previousY The previous amount of token Y
     * @param amountX The current amount of token X
     * @param amountY The current amount of token Y
     * @return feesX The fees of token X
     * @return feesY The fees of token Y
     */
    function getFeesAtId(
        uint16 binStep,
        uint24 id,
        uint256 previousX,
        uint256 previousY,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 feesX, uint256 feesY) {
        uint256 price = PriceHelper.getPriceFromId(id, binStep);

        uint256 previousLiquidity = getLiquidityFromPrice(previousX, previousY, price);
        uint256 currentLiquidity = getLiquidityFromPrice(amountX, amountY, price);

        return getFeesFromLiquidities(previousLiquidity, currentLiquidity, amountX, amountY);
    }

    /**
     * @dev Return the fees earned of a given user at a given id from a given liquidity position
     * @param previousLiquidity The previous liquidity
     * @param currentLiquidity The current liquidity
     * @param amountX The current amount of token X
     * @param amountY The current amount of token Y
     * @return feesX The fees of token X
     * @return feesY The fees of token Y
     */
    function getFeesFromLiquidities(
        uint256 previousLiquidity,
        uint256 currentLiquidity,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 feesX, uint256 feesY) {
        if (currentLiquidity > previousLiquidity) {
            uint256 feesinL = (currentLiquidity - previousLiquidity);

            feesX = feesinL.mulDivRoundDown(amountX, currentLiquidity);
            feesY = feesinL.mulDivRoundDown(amountY, currentLiquidity);
        }
    }

    /**
     * @dev Return the share amount for a given liquidity at a given id
     * @param lbPair The pair
     * @param id The id
     * @param liquidity The liquidity
     * @param price The price
     * @return The share amount
     */
    function getShareForLiquidity(ILBPair lbPair, uint256 id, uint256 liquidity, uint256 price)
        internal
        view
        returns (uint256)
    {
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id.safe24());
        uint256 binLiquidity = getLiquidityFromPrice(binReserveX, binReserveY, price);

        uint256 totalShares = lbPair.totalSupply(id);

        return binLiquidity == 0 ? 0 : liquidity.mulDivRoundDown(totalShares, binLiquidity);
    }

    /**
     * @dev Return the liquidity of a given amount of x and y at a given id
     * @param amountX The amount of token X
     * @param amountY The amount of token Y
     * @param id The id
     * @param binStep The binStep of the pair
     * @return liquidity The liquidity
     */
    function getLiquidityFromId(uint256 amountX, uint256 amountY, uint24 id, uint16 binStep)
        internal
        pure
        returns (uint256 liquidity)
    {
        return getLiquidityFromPrice(amountX, amountY, PriceHelper.getPriceFromId(id, binStep));
    }

    /**
     * @dev Return the liquidity of a given amount of x and y at a given price
     * The amount is returned as a 128.128 fixed point number
     * @param amountX The amount of token X
     * @param amountY The amount of token Y
     * @param price The price
     * @return liquidity The liquidity
     */
    function getLiquidityFromPrice(uint256 amountX, uint256 amountY, uint256 price)
        internal
        pure
        returns (uint256 liquidity)
    {
        return BinHelper.getLiquidity(amountX, amountY, price) >> 128;
    }
}
