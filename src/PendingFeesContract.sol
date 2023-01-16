// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./periphery/PendingFees.sol";

/// @title Liquidity Book periphery contract for Pending Fees
/// @author Trader Joe
/// @notice Periphery contract to help compute pending fees from ids.
contract PendingFeesContract {
    using PendingFees for address;

    /// @notice Return the fees amounts that are cached for a given user
    /// @param LBPair the address of the pair
    /// @param user the address of the user
    /// @return amountX the amount of tokenX that are cached
    /// @return amountY the amount of tokenY that are cached
    function getCachedFees(address LBPair, address user) external view returns (uint256 amountX, uint256 amountY) {
        return LBPair.getCachedFees(user);
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
        external
        view
        returns (
            uint256 cachedX,
            uint256 cachedY,
            uint256[] memory idsWithFees,
            uint256[] memory amountsX,
            uint256[] memory amountsY
        )
    {
        return LBPair.getIdsWithFees(user, ids);
    }
}
