// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

import "../src/periphery/NonEmptyBinHelper.sol";
import "../src/LiquidityHelperContract.sol";

contract TestNonEmptyBinHelper is TestHelper {
    LiquidityHelperContract helper;

    function setUp() public override {
        super.setUp();

        helper = new LiquidityHelperContract();
    }

    function test_GetPopulatedBinsReserves() public {
        (uint256[] memory ids,) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        NonEmptyBinHelper.PopulatedBin[] memory bins =
            helper.getPopulatedBinsReserves(lbPair0, uint24(ids[0]), uint24(ids[ids.length - 1]), 0);

        for (uint256 i; i < ids.length; i++) {
            assertEq(bins[i].id, uint24(ids[i]), "test_GetPopulatedBinsReserves::1");

            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(bins[i].id);

            assertEq(bins[i].reserveX, reserveX, "test_GetPopulatedBinsReserves::2");
            assertEq(bins[i].reserveY, reserveY, "test_GetPopulatedBinsReserves::3");
        }

        NonEmptyBinHelper.PopulatedBin[] memory binsReverse =
            helper.getPopulatedBinsReserves(lbPair0, uint24(ids[ids.length - 1]), uint24(ids[0]), 0);

        assertEq(binsReverse.length, bins.length, "test_GetPopulatedBinsReserves::4");

        for (uint256 i; i < binsReverse.length; i++) {
            uint256 reverseI = binsReverse.length - 1 - i;

            assertEq(binsReverse[reverseI].id, bins[i].id, "test_GetPopulatedBinsReserves::5");
            assertEq(binsReverse[reverseI].reserveX, bins[i].reserveX, "test_GetPopulatedBinsReserves::6");
            assertEq(binsReverse[reverseI].reserveY, bins[i].reserveY, "test_GetPopulatedBinsReserves::7");
        }

        uint24 start = uint24(ids[ids.length - 1]);
        uint24 end = start + 20;

        bins = helper.getPopulatedBinsReserves(lbPair0, start, end, 0);

        assertLt(bins.length, 20, "test_GetPopulatedBinsReserves::8");

        uint256 binsI;
        for (uint24 i; i < 20; i++) {
            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(start + i);

            if (reserveX > 0 || reserveY > 0) {
                assertEq(bins[binsI].id, start + i, "test_GetPopulatedBinsReserves::9");
                assertEq(bins[binsI].reserveX, reserveX, "test_GetPopulatedBinsReserves::10");
                assertEq(bins[binsI].reserveY, reserveY, "test_GetPopulatedBinsReserves::11");

                binsI++;
            }
        }

        bins = helper.getPopulatedBinsReserves(lbPair0, 2 ** 23 - 887272, 2 ** 23 + 887272, 100);

        assertLt(bins.length, 100, "test_GetPopulatedBinsReserves::12");

        assertEq(lbPair0.getNextNonEmptyBin(true, bins[0].id), type(uint24).max, "test_GetPopulatedBinsReserves::13");
        assertEq(lbPair0.getNextNonEmptyBin(false, bins[bins.length - 1].id), 0, "test_GetPopulatedBinsReserves::14");

        bins = helper.getPopulatedBinsReserves(lbPair0, 2 ** 23 - 887272, 2 ** 23 + 887272, 1);

        assertEq(bins.length, 1, "test_GetPopulatedBinsReserves::15");
        assertEq(bins[0].id, 8112267, "test_GetPopulatedBinsReserves::16");

        bins = helper.getPopulatedBinsReserves(lbPair0, 2 ** 23 + 887272, 2 ** 23 - 887272, 1);

        assertEq(bins.length, 1, "test_GetPopulatedBinsReserves::17");
        assertEq(bins[0].id, 8112296, "test_GetPopulatedBinsReserves::18");
    }

    function test_GetBinsReserveOf() public {
        uint24 activeId = lbPair0.getActiveId();

        (uint24 id, NonEmptyBinHelper.PopulatedBinUser[] memory bins) =
            helper.getBinsReserveOf(lbPair0, alice, 0, 10, 10);

        assertEq(id, activeId, "test_GetBinsReserveOf::1");
        assertEq(bins.length, 0, "test_GetBinsReserveOf::2");

        (uint256[] memory ids,) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, 0, 10, 10);

        assertEq(id, activeId, "test_GetBinsReserveOf::3");
        assertEq(bins.length, ids.length, "test_GetBinsReserveOf::4");

        for (uint256 i; i < bins.length; i++) {
            assertEq(bins[i].id, uint24(ids[i]), "test_GetBinsReserveOf::5");

            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(bins[i].id);
            uint256 shares = lbPair0.balanceOf(alice, bins[i].id);
            uint256 totalShares = lbPair0.totalSupply(bins[i].id);

            assertEq(bins[i].reserveX, reserveX, "test_GetBinsReserveOf::6");
            assertEq(bins[i].reserveY, reserveY, "test_GetBinsReserveOf::7");
            assertGt(shares, 0, "test_GetBinsReserveOf::8");
            assertEq(bins[i].shares, shares, "test_GetBinsReserveOf::9");
            assertEq(bins[i].totalShares, totalShares, "test_GetBinsReserveOf::10");
        }

        swapNbBins(lbPair0, false, 10);

        (uint256[] memory ids2,) = addLiquidity(alice, lbPair0, 1e18, 20e6, 2, 2);

        activeId = lbPair0.getActiveId();
        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, activeId, 20, 20);

        assertEq(id, activeId, "test_GetBinsReserveOf::11");
        assertEq(bins.length, 10, "test_GetBinsReserveOf::12");

        for (uint256 i; i < bins.length; i++) {
            if (i < ids.length) {
                assertEq(bins[i].id, uint24(ids[i]), "test_GetBinsReserveOf::13");
            } else {
                assertEq(bins[i].id, uint24(ids2[i - ids.length]), "test_GetBinsReserveOf::14");
            }

            (uint128 reserveX, uint128 reserveY) = lbPair0.getBin(bins[i].id);
            uint256 shares = lbPair0.balanceOf(alice, bins[i].id);
            uint256 totalShares = lbPair0.totalSupply(bins[i].id);

            assertEq(bins[i].reserveX, reserveX, "test_GetBinsReserveOf::15");
            assertEq(bins[i].reserveY, reserveY, "test_GetBinsReserveOf::16");
            assertGt(shares, 0, "test_GetBinsReserveOf::17");
            assertEq(bins[i].shares, shares, "test_GetBinsReserveOf::18");
            assertEq(bins[i].totalShares, totalShares, "test_GetBinsReserveOf::19");
        }

        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, activeId, 0, 20);

        assertEq(id, activeId, "test_GetBinsReserveOf::20");
        assertEq(bins.length, 2, "test_GetBinsReserveOf::21");

        for (uint256 i; i < bins.length; i++) {
            assertEq(bins[i].id, uint24(ids2[i + 1]), "test_GetBinsReserveOf::22");
        }

        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, activeId, 20, 0);

        assertEq(id, activeId, "test_GetBinsReserveOf::23");
        assertEq(bins.length, 9, "test_GetBinsReserveOf::24");

        for (uint256 i; i < bins.length; i++) {
            if (i < ids.length) {
                assertEq(bins[i].id, uint24(ids[i]), "test_GetBinsReserveOf::25");
            } else {
                assertEq(bins[i].id, uint24(ids2[i - ids.length]), "test_GetBinsReserveOf::26");
            }
        }

        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, activeId, 0, 0);

        assertEq(id, activeId, "test_GetBinsReserveOf::27");
        assertEq(bins.length, 0, "test_GetBinsReserveOf::28");

        (id, bins) = helper.getBinsReserveOf(lbPair0, alice, activeId, type(uint24).max, type(uint24).max);

        assertEq(id, activeId, "test_GetBinsReserveOf::29");
        assertEq(bins.length, 10, "test_GetBinsReserveOf::30");
    }
}
