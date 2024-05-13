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
            assertEq(bins[i].id, uint24(ids[i]), "test_GetPopulatedBins::1");

            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(bins[i].id);

            assertEq(bins[i].reserveX, reserveX, "test_GetPopulatedBins::2");
            assertEq(bins[i].reserveY, reserveY, "test_GetPopulatedBins::3");
        }

        NonEmptyBinHelper.PopulatedBin[] memory binsReverse =
            helper.getPopulatedBins(lbPair0, uint24(ids[ids.length - 1]), uint24(ids[0]));

        assertEq(binsReverse.length, bins.length, "test_GetPopulatedBins::4");

        for (uint256 i; i < binsReverse.length; i++) {
            assertEq(binsReverse[i].id, bins[i].id, "test_GetPopulatedBins::5");
            assertEq(binsReverse[i].reserveX, bins[i].reserveX, "test_GetPopulatedBins::6");
            assertEq(binsReverse[i].reserveY, bins[i].reserveY, "test_GetPopulatedBins::7");
        }

        uint24 start = uint24(ids[ids.length - 1]);
        uint24 end = start + 20;

        bins = helper.getPopulatedBins(lbPair0, start, end);

        assertLt(bins.length, 20, "test_GetPopulatedBins::8");

        uint256 binsI;
        for (uint24 i; i < 20; i++) {
            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(start + i);

            if (reserveX > 0 || reserveY > 0) {
                assertEq(bins[binsI].id, start + i, "test_GetPopulatedBins::9");
                assertEq(bins[binsI].reserveX, reserveX, "test_GetPopulatedBins::10");
                assertEq(bins[binsI].reserveY, reserveY, "test_GetPopulatedBins::11");

                binsI++;
            }
        }
    }
}
