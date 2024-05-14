// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
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

    struct PopulatedBinUser {
        uint24 id;
        uint128 reserveX;
        uint128 reserveY;
        uint128 userReserveX;
        uint128 userReserveY;
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
        internal
        view
        returns (bytes memory)
    {
        (start, end) = start < end
            ? (start == 0 ? (0, end) : (start - 1, end))
            : (start == type(uint24).max ? (end, start) : (start + 1, end));

        length = length == 0 ? (end > start ? end - start : start - end) : length;

        bytes memory ids = new bytes(uint256(length) * 3); // pessimistic memory allocation of 3 bytes per id

        uint256 populatedBinCount = 0;
        uint256 memValue = ids.length;
        uint256 memSlot;

        assembly {
            memSlot := ids
        }

        uint24 id = start;
        bool swapForY = start > end;
        for (uint256 i; i < length && populatedBinCount < length; ++i) {
            id = pair.getNextNonEmptyBin(swapForY, id);

            if (swapForY ? id < end || id == type(uint24).max : id > end || id == 0) break;

            ++populatedBinCount;

            assembly {
                memValue := or(shl(24, memValue), id)
                memSlot := add(memSlot, 3)

                mstore(memSlot, memValue)
            }
        }

        assembly {
            mstore(ids, mul(3, populatedBinCount))
        }

        return ids;
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
        internal
        view
        returns (PopulatedBin[] memory)
    {
        bytes memory ids = getPopulatedBinsId(pair, start, end, length);

        uint256 populatedBinCount = ids.length / 3;
        PopulatedBin[] memory populatedBins = new PopulatedBin[](populatedBinCount);

        uint256 memSlot;
        assembly {
            memSlot := add(ids, 0x1d)
        }

        uint24 id;

        for (uint256 i; i < populatedBinCount; ++i) {
            assembly {
                memSlot := add(memSlot, 3)
                id := shr(232, mload(memSlot))
            }

            (uint128 reserveX, uint128 reserveY) = pair.getBin(id);
            populatedBins[i] = PopulatedBin(id, reserveX, reserveY);
        }

        return populatedBins;
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
        internal
        view
        returns (uint24, PopulatedBinUser[] memory)
    {
        if (id == 0) id = pair.getActiveId();

        bytes memory idsLeft =
            lengthLeft == 0 ? new bytes(0) : getPopulatedBinsId(pair, lengthRight == 0 ? id : id - 1, 0, lengthLeft);
        bytes memory idsRight =
            lengthRight == 0 ? new bytes(0) : getPopulatedBinsId(pair, id, type(uint24).max, lengthRight);

        uint256 populatedBinCountLeft = idsLeft.length / 3;
        uint256 populatedBinCountRight = idsRight.length / 3;
        uint256 populatedBinCount = populatedBinCountLeft + populatedBinCountRight;

        PopulatedBinUser[] memory userBins = new PopulatedBinUser[](populatedBinCount);

        uint256 memSlot;

        assembly {
            memSlot := add(add(idsLeft, 0x20), mul(populatedBinCountLeft, 3)) // Start at the end to reorder the ids
        }

        ILBPair pair_ = pair; // Avoid stack too deep error
        address user_ = user;

        uint256 i;
        while (i < populatedBinCountLeft) {
            uint24 binId;
            assembly {
                memSlot := sub(memSlot, 3)
                binId := shr(232, mload(memSlot))
            }

            uint256 shares = pair_.balanceOf(user_, binId);

            if (shares > 0) {
                (uint128 reserveX, uint128 reserveY) = pair_.getBin(binId);
                uint256 totalShares = pair_.totalSupply(binId);

                (uint128 userReserveX, uint128 userReserveY) = totalShares == 0
                    ? (0, 0)
                    : (
                        uint128(Uint256x256Math.mulDivRoundDown(shares, reserveX, totalShares)),
                        uint128(Uint256x256Math.mulDivRoundDown(shares, reserveY, totalShares))
                    );

                userBins[i++] = PopulatedBinUser(binId, reserveX, reserveY, userReserveX, userReserveY);
            } else {
                --populatedBinCountLeft;
            }
        }

        populatedBinCount = populatedBinCountLeft + populatedBinCountRight;

        assembly {
            memSlot := add(idsRight, 0x1d)
        }

        while (i < populatedBinCount) {
            uint24 binId;
            assembly {
                memSlot := add(memSlot, 3)
                binId := shr(232, mload(memSlot))
            }

            uint256 shares = pair_.balanceOf(user_, binId);

            if (shares > 0) {
                (uint128 reserveX, uint128 reserveY) = pair_.getBin(binId);
                uint256 totalShares = pair_.totalSupply(binId);

                (uint128 userReserveX, uint128 userReserveY) = totalShares == 0
                    ? (0, 0)
                    : (
                        uint128(Uint256x256Math.mulDivRoundDown(shares, reserveX, totalShares)),
                        uint128(Uint256x256Math.mulDivRoundDown(shares, reserveY, totalShares))
                    );

                userBins[i++] = PopulatedBinUser(binId, reserveX, reserveY, userReserveX, userReserveY);
            } else {
                --populatedBinCount;
            }
        }

        assembly {
            mstore(userBins, populatedBinCount)
        }

        return (id, userBins);
    }
}
