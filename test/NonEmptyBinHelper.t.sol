// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

import "../src/periphery/NonEmptyBinHelper.sol";
import "../src/NonEmptyBinHelperContract.sol";

contract TestNonEmptyBinHelper is TestHelper {
    NonEmptyBinHelperContract helper;

    function setUp() public override {
        super.setUp();

        helper = new NonEmptyBinHelperContract();
    }

    function test_GetPopulatedBins() public {
        (uint256[] memory ids,) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        NonEmptyBinHelper.PopulatedBin[] memory bins =
            helper.getPopulatedBins(lbPair0, uint24(ids[0]), uint24(ids[ids.length - 1]));

        for (uint256 i; i < ids.length; i++) {
            assertEq(bins[i].id, uint24(ids[i]), "test_GetPopulatedBins::0");

            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(bins[i].id);

            assertEq(bins[i].reserveX, reserveX, "test_GetPopulatedBins::1");
            assertEq(bins[i].reserveY, reserveY, "test_GetPopulatedBins::2");
        }
    }
}
