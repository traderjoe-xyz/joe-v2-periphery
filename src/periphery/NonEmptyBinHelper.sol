// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

/**
 * @title Liquidity Book periphery library for fetching non-empty bins.
 * @notice Periphery library to help fetch the non-empty bins of a liquidity book.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
library NonEmptyBinHelper {
    struct PopulatedBin {
        uint24 id;
        uint128 reserveX;
        uint128 reserveY;
    }

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
        internal
        view
        returns (PopulatedBin[] memory)
    {
        (start, end) = start < end ? (start, end) : (end, start);

        start = start == 0 ? 0 : --start;
        length = length == 0 ? end - start : length;

        PopulatedBin[] memory populatedBins = new PopulatedBin[](length); // pessimistic memory allocation

        uint24 id = start;
        uint256 populatedBinCount = 0;

        for (uint256 i; i < length && populatedBinCount < length; ++i) {
            id = pair.getNextNonEmptyBin(false, id);

            if (id > end || id == 0) break;

            (uint128 reserveX, uint128 reserveY) = pair.getBin(id);
            populatedBins[populatedBinCount++] = PopulatedBin(id, reserveX, reserveY);
        }

        assembly {
            mstore(populatedBins, populatedBinCount)
        }

        return populatedBins;
    }
}
