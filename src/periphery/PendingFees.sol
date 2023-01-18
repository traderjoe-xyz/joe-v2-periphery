// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBPair.sol";

/// @title Liquidity Book periphery library for Pending Fees
/// @author Trader Joe
/// @notice Periphery library to help compute pending fees from ids.
library PendingFees {
    /// @notice Return the fees amounts that are cached for a given user
    /// @param LBPair the address of the pair
    /// @param user the address of the user
    /// @return amountX the amount of tokenX that are cached
    /// @return amountY the amount of tokenY that are cached
    function getCachedFees(address LBPair, address user) internal view returns (uint256 amountX, uint256 amountY) {
        (amountX, amountY) = ILBPair(LBPair).pendingFees(user, new uint256[](0));
    }

    /// @notice Return the ids and amounts that have fees for a given user in the given list of ids
    /// @dev The returned arrays will be equal or smaller than the given arrays
    /// @param LBPair the address of the pair
    /// @param user the address of the user
    /// @param ids the list of ids where the user want to know if there are pending fees
    /// @return cachedX the amount of tokenX that are cached
    /// @return cachedY the amount of tokenY that are cached
    /// @return idsWithFees the list of ids that have pending fees
    /// @return amountsX the list of amount of tokenX that are pending for each id
    /// @return amountsY the list of amount of tokenY that are pending for each id
    function getIdsWithFees(address LBPair, address user, uint256[] memory ids)
        internal
        view
        returns (
            uint256 cachedX,
            uint256 cachedY,
            uint256[] memory idsWithFees,
            uint256[] memory amountsX,
            uint256[] memory amountsY
        )
    {
        idsWithFees = new uint256[](ids.length);
        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        uint256[] memory id = new uint256[](1);

        (cachedX, cachedY) = getCachedFees(LBPair, user);

        uint256 j;
        for (uint256 i; i < ids.length;) {
            id[0] = ids[i];

            (uint256 amountX, uint256 amountY) = ILBPair(LBPair).pendingFees(user, id);

            unchecked {
                if (amountX > cachedX || amountY > cachedY) {
                    idsWithFees[j] = ids[i];

                    if (amountX > cachedX) amountsX[j] = amountX - cachedX;
                    if (amountY > cachedY) amountsY[j] = amountY - cachedY;

                    ++j;
                }

                ++i;
            }
        }

        // resize the array, safe because we only decrease the size
        assembly {
            mstore(idsWithFees, j)
            mstore(amountsX, j)
            mstore(amountsY, j)
        }
    }
}
