// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILBPair, NonEmptyBinHelper} from "./periphery/NonEmptyBinHelper.sol";

/**
 * @title Liquidity Book periphery contract for fetching non-empty bins.
 * @notice Periphery contract to help fetch the non-empty bins of a liquidity book.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
contract NonEmptyBinHelperContract {
    /**
     * @notice Fetches the non-empty bins of a liquidity book pair from [start, end].
     *  If length is specified, it will return the first `length` non-empty bins.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return populatedBins The populated bins.
     */
    function getPopulatedBins(ILBPair pair, uint24 start, uint24 end, uint24 length)
        external
        view
        returns (NonEmptyBinHelper.PopulatedBin[] memory)
    {
        return NonEmptyBinHelper.getPopulatedBins(pair, start, end, length);
    }
}
