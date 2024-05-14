// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {LiquidityHelper} from "./periphery/LiquidityHelper.sol";
import {NonEmptyBinHelper} from "./periphery/NonEmptyBinHelper.sol";

/**
 * @title Liquidity Book periphery contract for Liquidity, Fees Amounts and bin fetching.
 * @notice Periphery contract to help compute liquidity, fees amounts from amounts and ids and fetch bins.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
contract LiquidityHelperContract {
    /**
     * @dev Return the shares of the receipt token for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return balances The balance of the receipt token for each id
     */
    function getSharesOf(ILBPair lbPair, address user, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances)
    {
        return LiquidityHelper.getSharesOf(lbPair, user, ids);
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
        external
        view
        returns (uint256[] memory liquidities)
    {
        return LiquidityHelper.getLiquiditiesOf(lbPair, user, ids);
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
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsOf(lbPair, user, ids);
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
    ) external view returns (uint256[] memory shares) {
        return LiquidityHelper.getSharesForAmounts(lbPair, ids, amountsX, amountsY);
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
    ) external view returns (uint256[] memory liquidities) {
        return LiquidityHelper.getLiquiditiesForAmounts(lbPair, ids, amountsX, amountsY);
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
        external
        view
        returns (uint256[] memory liquidities)
    {
        return LiquidityHelper.getLiquiditiesForShares(lbPair, ids, shares);
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
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsForShares(lbPair, ids, shares);
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
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsForLiquidities(lbPair, ids, liquidities);
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
        external
        view
        returns (uint256[] memory shares)
    {
        return LiquidityHelper.getSharesForLiquidities(lbPair, ids, liquidities);
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
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory feesX, uint256[] memory feesY)
    {
        return LiquidityHelper.getAmountsAndFeesEarnedOf(lbPair, user, ids, previousX, previousY);
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
    ) external view returns (uint256[] memory feeShares, uint256[] memory feesX, uint256[] memory feesY) {
        return LiquidityHelper.getFeeSharesAndFeesEarnedOf(lbPair, user, ids, previousLiquidities);
    }

    /**
     * @dev Fetch the non-empty bins ids of a liquidity book pair from [start, end].
     * If length is specified, it will return the first `length` non-empty bins.
     * Returns the ids in a packed bytes array, where each id is 3 bytes.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return ids The non-empty bins ids.
     */
    function getPopulatedBinsId(ILBPair pair, uint24 start, uint24 end, uint24 length)
        external
        view
        returns (bytes memory)
    {
        return NonEmptyBinHelper.getPopulatedBinsId(pair, start, end, length);
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [start, end].
     *  If length is specified, it will return the first `length` non-empty bins.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return populatedBins The populated bins.
     */
    function getPopulatedBinsReserves(ILBPair pair, uint24 start, uint24 end, uint24 length)
        external
        view
        returns (NonEmptyBinHelper.PopulatedBin[] memory)
    {
        return NonEmptyBinHelper.getPopulatedBinsReserves(pair, start, end, length);
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [start, end] where the user has liquidity.
     * If id is not specified, it will use the active bin id of the pair.
     * Will check `lengthLeft` non-empty bins on the left and `lengthRight` non-empty bins on the right, so if the user
     * has liquidity only after the `lengthLeft + 1` bin on the left and `lengthRight + 1` bin on the right, it will return
     * an empty array.
     * @param pair The liquidity book pair.
     * @param user The user.
     * @param id The specific bin id. (optional)
     * @param lengthLeft The number of non-empty bins to fetch on the left.
     * @param lengthRight The number of non-empty bins to fetch on the right.
     * @return id The bin id used. (id id was not specified, will return the active bin id)
     * @return populatedBins The populated bins.
     */
    function getBinsReserveOf(ILBPair pair, address user, uint24 id, uint24 lengthLeft, uint24 lengthRight)
        external
        view
        returns (uint24, NonEmptyBinHelper.PopulatedBinUser[] memory)
    {
        return NonEmptyBinHelper.getBinsReserveOf(pair, user, id, lengthLeft, lengthRight);
    }
}
